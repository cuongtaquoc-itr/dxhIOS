public protocol BLEModeMangerCallback {
    func onNewConnection(bluetoothComDevice: BluetoothComDevice)
    func canCommunicateThroughIB(bluetoothComDevice: BluetoothComDevice)
    func onFailedConnection(deviceID: String)
    func onLostConnection(bluetoothComDevice: BluetoothComDevice, message: String?)
    func alreadyRemovedDevice(deviceID: String)
    func removedDevice(bluetoothComDevice: BluetoothComDevice)
    func scanDidNotFound(deviceID: String)
    func blueToothOn()
    func blueToothOff()
    func scanFound(tioPeripheral: TIOPeripheral)
}
