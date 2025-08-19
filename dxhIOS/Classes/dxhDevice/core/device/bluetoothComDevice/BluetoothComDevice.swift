import Foundation

public class BluetoothComDevice: DXHDevice {
    private let TAG = "BluetoothComDevice"

    var tioPeripheral: TIOPeripheral
    private let bluetoothComConnectionCallback: BluetoothComConnectionCallback
    
    
    public var bluetoothMacAddress: String
    
    
    public init(deviceID: String,
                tioPeripheral: TIOPeripheral,
                comDeviceCallback: ComDeviceCallback,
                deviceInfoUpdateCallback: DeviceInfoUpdateCallback,
                bluetoothComConnectionCallback: BluetoothComConnectionCallback,
                appInfo: String
    ) {
        self.tioPeripheral = tioPeripheral
        self.bluetoothComConnectionCallback = bluetoothComConnectionCallback
        self.bluetoothMacAddress = tioPeripheral.identifier.uuidString
        super.init(deviceInfoUpdateCallback: deviceInfoUpdateCallback, comDeviceCallback: comDeviceCallback, appInfo: appInfo)
        self.deviceID = deviceID
        self.connectionType = ConnectionType.BLUETOOTH
    }
    
    func connect() {
        MyLog.logAndWriteFile(tag: deviceID, message: "\(TAG)-connect \(tioPeripheral.cbPeripheral)")
        self.tioPeripheral.delegate = self
        self.tioPeripheral.connect()
    }
    override func send(data: Data) {
        MyLog.logAndWriteFile(tag: deviceID, message: "SEND: \(data.count) \(data.toHexString())")
        lastDataSendTime = Date().timeIntervalSince1970
        if (isConnected()) {
            tioPeripheral.writeUARTData(data)
        }
        
    }
    
    public override func isConnected() -> Bool {
        return tioPeripheral.cbPeripheral.state == CBPeripheralState.connected
    }
    
    override func disconnect() {
        TIOManager.sharedInstance().removePeripheral(tioPeripheral)
        super.reset()
    }
    
    override func resetConnection() {
        TIOManager.sharedInstance().cancelPeripheralConnection(tioPeripheral)
        super.reset()
    }
    
    override func canCommunicateThroughIB() -> Bool {
        return schemaVersion != nil && randomKey != nil
    }
}


extension BluetoothComDevice: TIOPeripheralDelegate {
    public func tioPeripheralDidConnect(_ peripheral: TIOPeripheral!) {
        MyLog.logAndWriteFile(tag: deviceID, message: "\(TAG)-tioPeripheralDidConnect \(tioPeripheral.cbPeripheral)")
        tioPeripheral = peripheral
        sendDataInterval()

        queueSynPackageToSend(data: SynCmd.request())
        self.canSendCmd = true
        self.bluetoothComConnectionCallback.onConnected()
    }
    
    public func tioPeripheral(_ peripheral: TIOPeripheral!, didFailToConnectWithError error: Error!) {
        MyLog.logAndWriteFile(tag: deviceID, message: "\(TAG)-didFailToConnectWithError \(tioPeripheral.cbPeripheral)")
        self.bluetoothComConnectionCallback.onConnectFailed(bluetoothComDevice: self)
    }
    
    public func tioPeripheral(_ peripheral: TIOPeripheral!, didDisconnectWithError error: Error?) {
        MyLog.logAndWriteFile(tag: deviceID, message: "\(TAG)-didDisconnectWithError \(tioPeripheral.cbPeripheral) \(error)--\(error?.localizedDescription) -- \(peripheral.shallBeSaved)")
        self.bluetoothComConnectionCallback.onDisconnected(bluetoothComDevice: self, errorMessage: error?.localizedDescription)
        
        if(peripheral.shallBeSaved){
            if(error != nil) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5){
                    self.connect()
                }
            }
        }
    }
    
    public func tioPeripheral(_ peripheral: TIOPeripheral!, didReceiveUARTData data: Data!) {
        MyLog.log(tag: deviceID, message: "onDataReceived \(data.toHexString())", logPriority: 9)
        if security == nil {
            MyLog.logAndWriteFile(tag: deviceID, message: "onDataReceived \(data.toHexString())")
        }
        restartTimerProtocolKa()
        comDeviceCallback.onRawData(data: data)
    }
}


