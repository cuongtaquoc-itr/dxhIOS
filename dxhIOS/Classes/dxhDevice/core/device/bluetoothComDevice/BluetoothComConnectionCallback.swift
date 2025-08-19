public protocol BluetoothComConnectionCallback {
    func onConnected()
    func onConnectFailed(bluetoothComDevice: BluetoothComDevice)
    func onDisconnected(bluetoothComDevice: BluetoothComDevice, errorMessage: String?)
}
