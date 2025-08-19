import CoreBluetooth
import RxSwift

public class BleScanner: NSObject {
    public static var sharedInstance = BleScanner()
    private var scannerCallbacks: [ScannerCallback] = []
    private var manualStartScan = false
    private var devicesIdToScan: [String] = []
    private var scanTimeOutDispo: [String: Disposable] = [:]
    
    public override init() {
        super.init()
        TIOManager.sharedInstance().delegate = self
    }
    
    public func insertScannerCallback(_ callback: ScannerCallback) {
        scannerCallbacks.append(callback)
    }
    
    func removeScannerCallback(_ callback: ScannerCallback) {
        scannerCallbacks.removeAll {$0 === callback}
    }
    
    func scanForDevice(deviceID: String, address: String?, timeOut: Int = 0) {
        MyLog.log(tag: "SCANNER", message: "scanForDevice \(deviceID) \(timeOut)")
        
        devicesIdToScan.removeAll {$0 == deviceID}
        devicesIdToScan.append(deviceID)
        startTimeoutTimer(deviceID: deviceID, timeOut: timeOut)
        _startScan()
    }
    func stopScanForDevice(deviceID: String) {
        reloadScannedPeripheralList()
        
        devicesIdToScan.removeAll {$0 == deviceID}
        if(!shouldContinueScan()){
            stopScan()
        }
    }
    func removeKnownDevice(tioPeripheral: TIOPeripheral) {
        reloadScannedPeripheralList()
    }
    func stopScan() {
        manualStartScan = false
        _stopScan()
    }
    
    func startScan() -> Bool {
        manualStartScan = true
        return _startScan()
    }
    public func resumeScanIfNeed() {
        MyLog.log(tag: "SCANNER", message: "resumeScan")
        self._stopScan()
        if self.shouldContinueScan() {
            _startScan()
        }
    }
    func stopAll() {
        manualStartScan = false
        devicesIdToScan.removeAll()
        _stopScan()
    }
    private func _startScan() -> Bool {
        TIOManager.sharedInstance().startUpdateScan()
        MyLog.log(tag: "SCANNER", message: "startScan")
        return true
    }
    private func _stopScan() {
        TIOManager.sharedInstance().stopScan()
        MyLog.log(tag: "SCANNER", message: "stopScan")
    }
    private func startTimeoutTimer(deviceID: String, timeOut: Int) {
        scanTimeOutDispo[deviceID]?.dispose()
        
        if timeOut > 0 {
            let dispo = Observable<Int>
                .timer(.seconds(timeOut), scheduler: MainScheduler.instance)
                .subscribe(onNext: { _ in
                    self.devicesIdToScan.removeAll{$0 == deviceID}
                    self.scannerCallbacks.forEach{$0.didNotFound(deviceID: deviceID)}
                    if !self.shouldContinueScan() {
                        self._stopScan()
                    }
                })
            scanTimeOutDispo[deviceID] = dispo
        }
    }
    private func retreiveKnownPeripheral(deviceID: String, address: String?) -> TIOPeripheral? {
        var list: [TIOPeripheral] = []
        
        TIOManager.sharedInstance().peripherals.forEach { peripheral in
            if let tioPeripheral = peripheral as? TIOPeripheral {
                list.append(tioPeripheral)
            }
        }
       
        if let storedDevice = list.first(where: { $0.deviceID == deviceID })  {
            return storedDevice
        }
        return nil
    }
    private func reloadScannedPeripheralList(){
        TIOManager.sharedInstance().loadPeripherals()
    }
    
    private func shouldContinueScan() -> Bool {
        MyLog.log(tag: "SCANNER", message: "shouldContinueScan \(manualStartScan) \(!devicesIdToScan.isEmpty)")
        return manualStartScan || !devicesIdToScan.isEmpty
    }
}

extension BleScanner: TIOManagerDelegate {
    public func tioManagerBluetoothAvailable(_ manager: TIOManager!) {
        MyLog.log(tag: "SCANNER", message: "tioManagerBluetoothAvailable")
        scannerCallbacks.forEach { $0.blueToothOn() }
    }
    
    public func tioManagerBluetoothUnavailable(_ manager: TIOManager!) {
        MyLog.log(tag: "SCANNER", message: "tioManagerBluetoothUnavailable")
        scannerCallbacks.forEach { $0.blueToothOff() }
    }
    
    public func tioManager(_ manager: TIOManager!, didDiscover peripheral: TIOPeripheral!) {
        MyLog.log(tag: "SCANNER", message: "didDiscover \(peripheral.deviceID) \(peripheral.name)")
        
        let deviceID = peripheral.deviceID
        if(DeviceUtils.deviceRequireTokenToConnect(deviceName: deviceID)) {
            return
        }
        scanTimeOutDispo[deviceID]?.dispose()
        scannerCallbacks.forEach { $0.didFound(peripheral: peripheral) }
    }
    public func tioManager(_ manager: TIOManager!, didUpdate peripheral: TIOPeripheral!) {
        MyLog.log(tag: "SCANNER", message: "didUpdate \(peripheral.deviceID) \(peripheral.name)")
        let deviceID = peripheral.deviceID
        if(DeviceUtils.deviceRequireTokenToConnect(deviceName: deviceID)) {
            return
        }
        scanTimeOutDispo[deviceID]?.dispose()
        scannerCallbacks.forEach { $0.didFound(peripheral: peripheral) }
    }
    
    public func tioManager(_ manager: TIOManager!, didRetrievePeripheral peripheral: TIOPeripheral!) {
        MyLog.log(tag: "SCANNER", message: "didRetrievePeripheral \(peripheral.deviceID)")
    }
}
