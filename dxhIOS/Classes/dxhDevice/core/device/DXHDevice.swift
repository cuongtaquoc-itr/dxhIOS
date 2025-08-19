import Foundation
import Reachability
import RxSwift

public class DXHDevice: NSObject {
    public let appInfo: String

    var deviceInfoUpdateCallback: DeviceInfoUpdateCallback
    var comDeviceCallback: ComDeviceCallback

    var schemaVersion: Int?
    var randomKey: String?
    public var deviceID: String!
    var connectionType: ConnectionType

    var protocolVersion: Int = 0
    var apiVersion: Int = 0 // Indicate the version of firmware
    public var leadStatus: LeadStatus?
    public var studyStatus: String = ""

    var hwVersion: String = ""
    public var fwVersion: String = ""

    public var battLevel: Int = 0
    public var battCharging: Bool = false
    public var battLow: Bool = false
    public var chargingRemaining: Int = 0

    //=== Tcp ===//
    private var openTcpDisposable: Disposable?
    private lazy var tcpClientHandler: TcpClientHandler = TcpClientHandler(callback: self)
    var canSendCmd: Bool = true

    public func isTCPSocketOpened () -> Bool {
        return tcpClientHandler.isTCPSocketOpened()
    }
    //=== End Tcp ===//

    public var ecgConfig: ECGConfig?
    public var ecgData: Data?
    var security: AESManager?
    var mctInstance: MCTInstance? = nil


    // Communication
    private var sequenceNumber: Int = 0
    var deviceSequenceNumber: Int = 0
    var lastDataSendTime: Double = 0
    private var spReadyDisposable: Disposable?
    private var kaDisposable: Disposable?
    private var sendDataDisposable: Disposable?
    // End Communication


    // TODO Synchonize
    private var sendSynBuffer: [Data] = []
    private var sendCmdBuffer: [Data] = []
    private var sendDataBuffer: [Data] = []


    func send(data: Data){fatalError("Must Override")}
    func disconnect(){fatalError("Must Override")}
    func resetConnection(){fatalError("Must Override")}
    public func isConnected() -> Bool{fatalError("Must Override")}
    func canCommunicateThroughIB() -> Bool{fatalError("Must Override")}

    public init(deviceInfoUpdateCallback: DeviceInfoUpdateCallback, comDeviceCallback: ComDeviceCallback, appInfo: String){
        self.deviceInfoUpdateCallback = deviceInfoUpdateCallback
        self.comDeviceCallback = comDeviceCallback
        self.connectionType = ConnectionType.BLUETOOTH
        self.appInfo = appInfo

        super.init()
    }

    func reset() {
        schemaVersion = nil
        randomKey = nil

        sequenceNumber = 0
        deviceSequenceNumber = 0
        spReadyDisposable?.dispose()
        spReadyDisposable = nil
        spReadyDisposable = Observable<Int>
            .just(1)
            .subscribe(onNext: { _ in print("spReadyDisposable clear") })

        sendDataDisposable?.dispose()
        sendDataDisposable = nil
        sendDataDisposable = Observable<Int>
            .just(1)
            .subscribe(onNext: { _ in print("sendDataDisposable clear") })
        kaDisposable?.dispose()
        kaDisposable = nil
        kaDisposable = Observable<Int>
            .just(1)
            .subscribe(onNext: { _ in print("kaDisposable clear") })
        canSendCmd = true
    }

    func sendDataInterval() {
        sendDataDisposable =
        Observable<Int>
            .interval(.milliseconds(Constant.WRITE_WAIT_MILLIS), scheduler: MainScheduler.instance)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribe(onNext: {_ in
                if let dataToSend = self.getDataToSend() {
                    self.send(data: dataToSend)
                    return
                }


                if (Int(Date().timeIntervalSince1970 - self.lastDataSendTime) > Constant.TIME_SEND_KA_INTERVAL_SEC &&
                    self.canCommunicateThroughIB()
                ) {
                    self.send(data: self.buildKaFrame())
                }
            })
    }

    func sendDataToTCPServer(data: Data) {
        tcpClientHandler.sendData(data: data)
    }

    private func queuePackagesToSend(packages: [Data]) {
        for packet in packages {
            sendDataBuffer.append(packet)
        }
    }

    func queueSynPackageToSend(data: Data) {
        sendSynBuffer.append(data)
    }

    func queueCmdPackageToSend(data: Data) {
        sendCmdBuffer.append(data)
    }

    public func streamEcg(start: Bool) {
        MyLog.log(tag: deviceID, message: "STREAM ECG \(start)")
        queueCmdPackageToSend(data: SmUECG.request(enable: start))
    }

    public func confirmMctEvent(symptoms: [Int], deviceTriggerTime: Int64) {
        MyLog.log(tag: deviceID, message: "CONFIRM MCT \(symptoms) \(deviceTriggerTime)")
        queueCmdPackageToSend(data: SmEVENTCONFIRMED.request(eventTime: deviceTriggerTime, symptom: symptoms))
    }

    private func buildKaFrame()-> Data {
        let dataToSend = SmKA.request()
        let frame = FrameBuilder.usbBuildFrame(sequenceNumber: sequenceNumber, packets: [dataToSend])
        sequenceNumber = FrameUtils.calculateSequenceNumber(oldSequenceNumber: sequenceNumber, dataLength: dataToSend.count)
        return frame
    }


    private func getDataToSend() -> Data? {
        if (sendSynBuffer.count > 0) {
            return buildSyncFrame()
        }
        if (canSendCmd && sendCmdBuffer.count > 0) {
            return buildCmdFrame()
        }
        if (sendDataBuffer.count > 0) {
            return buildDataFrame()
        }
        return nil
    }

    private func buildSyncFrame()-> Data {
        var dataToSend: [Data] = []
        while sendSynBuffer.count > 0 {
            let data = sendSynBuffer.removeFirst()
            dataToSend.append(data)
        }

        return FrameBuilder.usbBuildSynFrame(packets: dataToSend)
    }
    private func buildCmdFrame()-> Data {
        var dataToSend: [Data] = []
        var dataLength = 0

        let data = sendCmdBuffer.removeFirst()
        dataToSend.append(data)
        dataLength += data.count

        canSendCmd = false

        let frame = FrameBuilder.usbBuildFrame(sequenceNumber: sequenceNumber, packets: dataToSend)
        sequenceNumber = FrameUtils.calculateSequenceNumber(oldSequenceNumber: sequenceNumber, dataLength: dataLength)
        return frame
    }
    private func buildDataFrame()-> Data {
        var dataToSend: [Data] = []
        var dataLength = 0
        var frameMaxLengthReached = false

        while sendDataBuffer.count > 0 && !frameMaxLengthReached {
            let peekData = sendDataBuffer[0]
            if (dataLength + peekData.count < Constant.MAX_FRAME_SIZE) {
                let data = sendDataBuffer.removeFirst()
                dataToSend.append(data)
                dataLength += data.count
                frameMaxLengthReached = false
            } else {
                frameMaxLengthReached = true
            }
        }

        let frame = FrameBuilder.usbBuildFrame(sequenceNumber: sequenceNumber, packets: dataToSend)
        sequenceNumber = FrameUtils.calculateSequenceNumber(oldSequenceNumber: sequenceNumber, dataLength: dataLength)
        return frame
    }
    func restartTimerProtocolKa() {
        comDeviceCallback.onKA()
        kaDisposable?.dispose()
        kaDisposable = Observable<Int>
            .just(1)
            .delay(.seconds(Constant.TIME_RECV_KA_INTERVAL_SEC), scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                MyLog.logAndWriteFile(tag: self.deviceID, message: "Device not send KA")
                self.comDeviceCallback.onError(error: "Device not send KA")
            })
    }

    func startTimerSpReady() {
        spReadyDisposable?.dispose()
        spReadyDisposable = Observable<Int>
            .timer(.seconds(Constant.TIME_WAIT_FOR_SPREADY_SEC), scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                MyLog.logAndWriteFile(tag: self.deviceID, message: "startTimerSpReady")
                self.queueCmdPackageToSend(data: SmSPREBOOT.request())
            })
    }
    func clearTimerSpReady() {
        spReadyDisposable?.dispose()
    }
}


//=== Tcp ===//
extension DXHDevice {
    func openTcpConnectionWithRetry() {
        openTcpDisposable?.dispose()
        openTcpDisposable = Observable<Int>
            .timer(.seconds(2), period: .seconds(30), scheduler: MainScheduler.instance)
            .subscribe(onNext: {_ in
                let reachability = try! Reachability()
                let connected = reachability.connection != .none
                if(connected){
                    self.tcpClientHandler.openTcpConnection()
                }
            })
    }
    func closeTcpConnectionAndStopRetry() {
        openTcpDisposable?.dispose()
        closeTcpConnection()
    }
    func closeTcpConnection() {
        tcpClientHandler.closeTcpConnection()
    }
}
extension DXHDevice: TCPClientCallback {
    func didTcpConnected() {
        MyLog.logAndWriteFile(tag: deviceID, message: "TCP CONNECTED")
        self.deviceInfoUpdateCallback.tcpConnected(dxhDevice: self)
        openTcpDisposable?.dispose()
        openTcpDisposable = nil
    }

    func didLostTcpConnection() {
        MyLog.logAndWriteFile(tag: deviceID, message: "TCP LOST CONNECTION")
        queueCmdPackageToSend(data: SmSPREBOOT.request())
        closeTcpConnection()
        self.deviceInfoUpdateCallback.tcpDisconnected(dxhDevice: self)
    }

    func didReceiveTcpData(data: Data?) {
        guard let data = data else {
            return
        }
        MyLog.log(tag: deviceID, message: "didReceiveTcpData \(data.toHexString())", logPriority: 9)
        queuePackagesToSend(packages: PackageBuilder.usbBuildPackages(channelID: ChannelID.STUDY_PROTOCOL, data: data))

    }

    func connectTcpFailed() {
        MyLog.logAndWriteFile(tag: deviceID, message: "TCP FAILED CONNECTION")
        closeTcpConnection()
    }

    func tcpTimeout() {
        MyLog.logAndWriteFile(tag: deviceID, message: "TCP CONNECTION TIMEOUT")
        closeTcpConnection()
    }
}

extension DXHDevice: Identifiable {}
