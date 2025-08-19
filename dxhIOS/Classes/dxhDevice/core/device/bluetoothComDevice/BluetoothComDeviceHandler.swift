import RxSwift
import Reachability
import Foundation

public class BluetoothComDeviceHandler {
    private let TAG = "BCD"
    private let deviceID: String
    private let tioPeripheral: TIOPeripheral
    private let deviceInfoUpdateCallback: DeviceInfoUpdateCallback
    private let bluetoothComCommunicationCallback: BluetoothComCommunicationCallback
    private let appInfo: String

    private var spDisposable: Disposable?
    public lazy var bluetoothComDevice: BluetoothComDevice = BluetoothComDevice(
        deviceID: deviceID,
        tioPeripheral: tioPeripheral,
        comDeviceCallback: self,
        deviceInfoUpdateCallback: deviceInfoUpdateCallback,
        bluetoothComConnectionCallback: self,
        appInfo: appInfo
    )
    lazy var frameParser: FrameParser = FrameParser(frameParserCallback: self)
    lazy var packetParser: PacketParser =  PacketParser(deviceId: deviceID, packetParserCallback: self)


    public init(deviceID: String,
                tioPeripheral: TIOPeripheral,
                deviceInfoUpdateCallback: DeviceInfoUpdateCallback,
                bluetoothComCommunicationCallback: BluetoothComCommunicationCallback,
                appInfo: String
    ) {
        self.deviceID = deviceID
        self.tioPeripheral = tioPeripheral
        self.deviceInfoUpdateCallback = deviceInfoUpdateCallback
        self.bluetoothComCommunicationCallback = bluetoothComCommunicationCallback
        self.appInfo = appInfo
    }

    func connect() {
        bluetoothComDevice.connect()
    }

    func disconnect() {
        spDisposable?.dispose()
        bluetoothComDevice.disconnect()
    }
   func resetConnection() {
        spDisposable?.dispose()
        bluetoothComDevice.resetConnection()
    }

    func isConnected()-> Bool {
        return bluetoothComDevice.isConnected()
    }

    private func handleRawData(data: Data) {
        frameParser.addData(data: data)
    }

    private func handleFrame(data: Data) {
        let result = FrameHandler.handle(deviceSequenceNumber: bluetoothComDevice.deviceSequenceNumber, frame: data)

        if (result.success) {
            bluetoothComDevice.deviceSequenceNumber = result.newDeviceSequenceNumber
            if let frameData = result.frameData {
                packetParser.handleFrameData(frameData: frameData)
            }
        } else {
            if(result.errorType == FrameErrorType.INVALID_SYNC_TOKEN){
                BleScanner.sharedInstance.removeKnownDevice(tioPeripheral: bluetoothComDevice.tioPeripheral)
            }

            bluetoothComDevice.resetConnection()
            onDisconnected(bluetoothComDevice: bluetoothComDevice, errorMessage: "Parse frame error")
        }
    }
    private func reset() {
        frameParser.reset()
    }
}

extension BluetoothComDeviceHandler: ComDeviceCallback {
    public func onRawData(data: Data) {
        self.handleRawData(data: data)
    }

    public func onError(error: String) {
        self.resetConnection()
    }

    public func onKA() {
        self.bluetoothComCommunicationCallback.onKA(bluetoothComDeviceHandler: self)
    }
}
extension BluetoothComDeviceHandler: BluetoothComConnectionCallback {
    public func onConnected() {
        self.bluetoothComCommunicationCallback.onConnected()
    }

    public func onConnectFailed(bluetoothComDevice: BluetoothComDevice) {
        self.bluetoothComCommunicationCallback.onConnectFailed(bluetoothComDeviceHandler: self)
    }

    public func onDisconnected(bluetoothComDevice: BluetoothComDevice, errorMessage: String?) {
        spDisposable?.dispose()
        self.bluetoothComCommunicationCallback.onDisconnected(
            bluetoothComDeviceHandler: self,
            errorMessage: errorMessage
        )
        self.reset()
        self.bluetoothComDevice.reset()
    }

}
extension BluetoothComDeviceHandler: FrameParserCallback {
    func onNewFrame(data: Data) {
        self.handleFrame(data: data)
    }
}
extension BluetoothComDeviceHandler: PacketParserCallback {
    func onSynPacket(data: Data) {
        MyLog.logAndWriteFile(tag: deviceID, message: "\(TAG)-onSynPacket")
        self.handleSynResponse(data: data)
    }

    func onIbPacket(data: Data) {
    }

    func onSpPacket(data: Data) {
        self.bluetoothComDevice.sendDataToTCPServer(data: data)
        self.restartTimerStudyProtocol()
    }

    func onSmCmdPacket(data: String) {
        MyLog.logAndWriteFile(tag: deviceID, message: "\(TAG)-onSmCmdPacket \(data)")
        bluetoothComDevice.canSendCmd = true
        switch SmCommand.parseCommand(value: data) {
        case .ID :
            handleIdResponse(data: data)
            break
        case .UECG :
            handleUECGResponse(data: data)
            break
        case .ECGCH_USB :
            handleECGCHResponse(data: data)
            break
        case .TCPSERVER :
            handleTCPSERVERResponse(data: data)
            break
        default:
            break
        }
    }

    func onSmNotifyPacket(data: String) {
        MyLog.logAndWriteFile(tag: deviceID, message: "\(TAG)-onSmNotifyPacket \(data)")
        switch Notification.parseNotification(value: data) {
        case .DEV_STAT:
            DevStatNotiHandler.handle(dxhDevice: bluetoothComDevice, notiString: data)
            break
        case .SPREADY :
            self.bluetoothComDevice.clearTimerSpReady()
            SpNotiHandler.handle(dxhDevice: bluetoothComDevice, data: data)
            break
        case .EVENT_TRIGGERED :
            EventTriggeredNotiHandler.handle(dxhDevice: bluetoothComDevice, data: data)
            break
        default:
            break
        }
        deviceInfoUpdateCallback.updateInfo(dxhDevice: bluetoothComDevice)
    }

    func onEcgPacket(data: Data) {
        self.bluetoothComDevice.ecgData = data
        self.deviceInfoUpdateCallback.updateECGData(dxhDevice: bluetoothComDevice)
    }


    private func handleSynResponse(data: Data) {
        guard let packageStringData = ByteUtils.subByteArray(src: data, startPos: 0, num: data.count - 1)?.toString()  else {
            return
        }

        SynHandler.parse(
            packageStringData: packageStringData,
            onSchemaVersion: { schemaVersion in
                bluetoothComDevice.schemaVersion = schemaVersion
            }, onDeviceSequenceNumber: { deviceSequenceNumber in
                bluetoothComDevice.deviceSequenceNumber = deviceSequenceNumber
            }, onRandomKey: { randomKey in
                bluetoothComDevice.randomKey = randomKey
            })
        if (bluetoothComDevice.schemaVersion != nil && bluetoothComDevice.randomKey != nil) {
            self.bluetoothComDevice.queueCmdPackageToSend(data: SmID.request())
            MyLog.logAndWriteFile(tag: deviceID, message: "\(TAG)-handleSynResponse \(bluetoothComDevice.schemaVersion) \(bluetoothComDevice.randomKey)")
        }
    }

    private func handleIdResponse(data: String) {
        guard let deviceId = SmIDHandler.parse(packageStringData: data) else {
            resetConnection()
            return
        }

        bluetoothComDevice.deviceID = deviceId
        bluetoothComDevice.security = AESManager(deviceName: deviceId)
        bluetoothComDevice.queueCmdPackageToSend(data: SmECGCH_USB.request())
        bluetoothComCommunicationCallback.onSynDone(bluetoothComDeviceHandler: self)
    }

    private func handleUECGResponse(data: String) {
        let result = SmUECGhandler.parse(packageStringData: data)
        if (result.success) {
            bluetoothComDevice.ecgConfig = result.ecgConfig
        } else {
            bluetoothComDevice.ecgConfig = nil
        }
        MyLog.logAndWriteFile(tag: deviceID, message: "\(TAG)-handleUECGResponse \(data)")
        deviceInfoUpdateCallback.updateECGConfig(dxhDevice: bluetoothComDevice)
    }

    private func handleECGCHResponse(data: String) {
        let success = SmECGCH_USBHandler.parse(packageStringData: data)
        if (!success) {
            resetConnection()
            return
        }
        bluetoothComDevice.startTimerSpReady()
        MyLog.logAndWriteFile(tag: deviceID, message: "\(TAG)-handleECGCHResponse \(data)")
        bluetoothComCommunicationCallback.canCommunicateThroughIB(bluetoothComDeviceHandler: self)
    }
    private func handleTCPSERVERResponse(data: String) {
        let tcpserverResult = SmTCPSERVERHandler.parse(packageStringData: data)
    }
    private func restartTimerStudyProtocol() {
        spDisposable?.dispose()
        spDisposable = Observable<Int>
            .just(1)
            .delay(.seconds(Constant.SP_CHANNEL_COMMUNICATION_TIME_OUT), scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                do {
                    let connected = try Reachability().connection != .unavailable && Reachability().connection != .none
                    if(connected){
                        MyLog.logAndWriteFile(tag: self.deviceID, message: "\(self.TAG)-SmREBOOT")
                        self.bluetoothComDevice.queueCmdPackageToSend(data: SmREBOOT.request())
                    }
                }catch { }
            })
    }
}
