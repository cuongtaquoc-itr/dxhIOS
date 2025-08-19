public protocol BluetoothComCommunicationCallback {
    func onConnected()
    func onConnectFailed(bluetoothComDeviceHandler: BluetoothComDeviceHandler)
    func onDisconnected(bluetoothComDeviceHandler: BluetoothComDeviceHandler, errorMessage: String?)
    func onKA(bluetoothComDeviceHandler: BluetoothComDeviceHandler)
    func onSynDone(bluetoothComDeviceHandler: BluetoothComDeviceHandler)
    func canCommunicateThroughIB(bluetoothComDeviceHandler: BluetoothComDeviceHandler)
}
