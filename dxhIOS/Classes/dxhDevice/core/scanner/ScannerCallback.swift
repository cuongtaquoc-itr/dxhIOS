import CoreBluetooth

public protocol ScannerCallback: class {
    func didFound(peripheral: TIOPeripheral)
    func didNotFound(deviceID: String)
    func blueToothOn()
    func blueToothOff()

}
