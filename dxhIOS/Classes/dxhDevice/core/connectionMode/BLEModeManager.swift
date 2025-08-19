import Foundation
import RxSwift

public class BLEModeManager {
    private let deviceInfoUpdateCallback: DeviceInfoUpdateCallback
    private let bleModeMangerCallback: BLEModeMangerCallback
    private let appInfo: String
    
    private let TAG = "BLEMM"
    private var manualConnectDeviceId: String?
    private var connectDeviceTimeoutDispo: Disposable?
    
    private var handshakedConnectedDevices: [BluetoothComDeviceHandler] = []
    private var pendingConnectDevices: [BluetoothComDeviceHandler] = []
    
    
    public init(deviceInfoUpdateCallback: DeviceInfoUpdateCallback, bleModeMangerCallback: BLEModeMangerCallback, appInfo: String) {
        MyLog.log(tag: TAG, message: "init")
        self.deviceInfoUpdateCallback = deviceInfoUpdateCallback
        self.bleModeMangerCallback = bleModeMangerCallback
        self.appInfo = appInfo
        BleScanner.sharedInstance.insertScannerCallback(self)
        
        let appBundleId = Bundle.main.bundleIdentifier ?? "com.octomed.octobeat"
        TIOManager.sharedInstance(with: DispatchQueue(label: "\(appBundleId)_queue", attributes: .concurrent))
    }
    
    public func scanConnectDevice(devieID: String, timeOut: Int) {
        TIOManager.sharedInstance().getCentralManager().retrieveConnectedPeripherals(withServices: [TIO.service_UUID()]).forEach {
            if($0.name != nil && $0.name!.contains(devieID)){
                TIOManager.sharedInstance().getCentralManager().cancelPeripheralConnection($0)
            }
        }
        
        manualConnectDeviceId = devieID
        BleScanner.sharedInstance.scanForDevice(deviceID: devieID, address: nil, timeOut: timeOut)
    }
    /**
     * Find device in list handshakedDevice, then
     * If no device found -> clean up and start new connect
     */
    public func connectToDevice(tioPeripheral: TIOPeripheral, deviceName: String, timeOut: Int) {
        var name:String
        if tioPeripheral.name.isEmpty {
            name = deviceName
        }
        else {
            name = tioPeripheral.name
        }
        
        MyLog.logAndWriteFile(tag: name, message: "\(TAG)-connectToDevice-\(name)")
        if let identifier = tioPeripheral.identifier {
            TIOManager.sharedInstance().getCentralManager().retrieveConnectedPeripherals(withServices: [TIO.service_UUID()]).forEach {
                if($0.identifier == identifier){
                    TIOManager.sharedInstance().getCentralManager().cancelPeripheralConnection($0)
                }
            }
        }
        if let knownDevice = TIOManager.sharedInstance().peripherals.first(where: {($0 as? TIOPeripheral)?.deviceID == name}) as? TIOPeripheral {
            if(knownDevice.shallBeSaved){
                if(knownDevice.cbPeripheral.state != CBPeripheralState.connected && knownDevice.cbPeripheral.state != CBPeripheralState.connected ){
                    knownDevice.connect()
                }
                startConnectionTimeOut(deviceID: name, address: knownDevice.identifier.uuidString, timeOut: timeOut)
                return
            }
        }

        pendingConnectDevices.removeAll {
            $0.bluetoothComDevice.deviceID == name
            || $0.bluetoothComDevice.bluetoothMacAddress == tioPeripheral.identifier.uuidString
        }
        handshakedConnectedDevices.removeAll {
            $0.bluetoothComDevice.deviceID == name
            || $0.bluetoothComDevice.bluetoothMacAddress == tioPeripheral.identifier.uuidString
        }
        
        let bluetoothComDeviceHandler = BluetoothComDeviceHandler(
            deviceID: name,
            tioPeripheral : tioPeripheral,
            deviceInfoUpdateCallback: self.deviceInfoUpdateCallback,
            bluetoothComCommunicationCallback : self,
            appInfo: appInfo
        )
        bluetoothComDeviceHandler.connect()
        self.pendingConnectDevices.append(bluetoothComDeviceHandler)
        startConnectionTimeOut(deviceID: name, address: tioPeripheral.identifier.uuidString, timeOut: timeOut)
    }
    
    public func reconnectBondedDevice() {
        MyLog.log(tag: TAG, message: "reconnectBondedDevice")
        TIOManager.sharedInstance().peripherals.forEach { peripheral in
            if let tioPeripheral = peripheral as? TIOPeripheral {
                MyLog.log(tag: TAG, message: "init bondedDevices-\(tioPeripheral.deviceID) \(tioPeripheral.shallBeSaved) \(tioPeripheral.name)")
                if(!tioPeripheral.shallBeSaved){
                    return
                }
                let pendingConnectDevice = pendingConnectDevices.first{pendingConnectDevice in
                    tioPeripheral.deviceID == pendingConnectDevice.bluetoothComDevice.deviceID
                    || pendingConnectDevice.bluetoothComDevice.bluetoothMacAddress == tioPeripheral.identifier.uuidString
                }
                if let pendingConnectDevice = pendingConnectDevice {
                    return
                }
                
                let bluetoothDevice = BluetoothComDeviceHandler(
                    deviceID: tioPeripheral.deviceID,
                    tioPeripheral : tioPeripheral,
                    deviceInfoUpdateCallback: self.deviceInfoUpdateCallback,
                    bluetoothComCommunicationCallback : self,
                    appInfo: appInfo
                )
                bluetoothDevice.connect()
                self.pendingConnectDevices.append(bluetoothDevice)
            }
        }
    }
    
    public func deleteAllDevices() {
        MyLog.logAndWriteFile(tag: TAG, message: "\(TAG)-deleteAllDevices")
        BleScanner.sharedInstance.stopAll()
        
        pendingConnectDevices.forEach {
            deleteDevice(bluetoothComDeviceHandler: $0)
        }
        handshakedConnectedDevices.forEach {
            deleteDevice(bluetoothComDeviceHandler: $0)
        }
        pendingConnectDevices.removeAll()
        handshakedConnectedDevices.removeAll()
        
        TIOManager.sharedInstance().removeAllPeripherals()
    }
    
    private func deleteDevice(bluetoothComDeviceHandler: BluetoothComDeviceHandler) {
        let deviceID = bluetoothComDeviceHandler.bluetoothComDevice.deviceID
        MyLog.logAndWriteFile(tag: deviceID!, message: "\(TAG)-deleteDevice2")
        
        bluetoothComDeviceHandler.disconnect()
        closeSslTcpConnection(bluetoothComDeviceHandler: bluetoothComDeviceHandler)
        bleModeMangerCallback.removedDevice(bluetoothComDevice: bluetoothComDeviceHandler.bluetoothComDevice)
    }
    
    public func deleteDevice(name: String, address: String?) {
        MyLog.logAndWriteFile(tag: name, message: "\(TAG)-deleteDevice1")
        
        guard let bluetoothComDeviceHandler =
                pendingConnectDevices.first(where: { $0.bluetoothComDevice.deviceID == name || $0.bluetoothComDevice.bluetoothMacAddress == address })
                ?? handshakedConnectedDevices.first(where: { $0.bluetoothComDevice.deviceID == name || $0.bluetoothComDevice.bluetoothMacAddress == address })
        else {
            bleModeMangerCallback.alreadyRemovedDevice(deviceID: name)
            return
        }
        
        deleteDevice(bluetoothComDeviceHandler: bluetoothComDeviceHandler)
    }
    
    public func retrieveHandshakedDevice(name: String?, address: String?)-> BluetoothComDeviceHandler? {
        return handshakedConnectedDevices.first {
            $0.bluetoothComDevice.deviceID == name || $0.bluetoothComDevice.bluetoothMacAddress == address
        }
    }
    
    public func retrieveHandshakedDevices()-> [BluetoothComDeviceHandler] {
        return handshakedConnectedDevices
    }
    
    private func startConnectionTimeOut(deviceID: String, address: String?, timeOut: Int) {
        connectDeviceTimeoutDispo?.dispose()
        if timeOut > 0 {
            connectDeviceTimeoutDispo = Observable<Int>
                .timer(.seconds(timeOut), scheduler: MainScheduler.instance)
                .subscribe(onNext: { _ in
                    MyLog.log(tag: deviceID, message: "\(self.TAG)-onConnectTimeOut")
                    
                    
                    if let bluetoothComDeviceHandler = self.pendingConnectDevices.first(where: { $0.bluetoothComDevice.deviceID == deviceID || $0.bluetoothComDevice.bluetoothMacAddress == address }) {
                        bluetoothComDeviceHandler.bluetoothComDevice.tioPeripheral.cancelConnection()
                    }
                    
                    self.bleModeMangerCallback.onFailedConnection(deviceID: deviceID)
                })
        }
    }
    
    private func closeSslTcpConnection(bluetoothComDeviceHandler: BluetoothComDeviceHandler) {
        let deviceID = bluetoothComDeviceHandler.bluetoothComDevice.deviceID
        do{
            try bluetoothComDeviceHandler.bluetoothComDevice.closeTcpConnection()
        }catch {
            MyLog.log(tag: deviceID!, message: "\(TAG)-closeSslTcpConnection error: \(error)")
        }
    }
    
    private func onBluetoothOff() {
        pendingConnectDevices.removeAll()
        handshakedConnectedDevices.removeAll()
    }
}

// MARK: BluetoothComCommunicationCallback
extension BLEModeManager: BluetoothComCommunicationCallback {
    public func onConnected() {
        MyLog.log(tag: "deviceID", message: "\(TAG)-onConnected")
    }
    
    public func onSynDone(bluetoothComDeviceHandler: BluetoothComDeviceHandler) {
        let deviceID = bluetoothComDeviceHandler.bluetoothComDevice.deviceID
        MyLog.log(tag: deviceID!, message: "\(TAG)-onSynDone")
        bleModeMangerCallback.onNewConnection(bluetoothComDevice: bluetoothComDeviceHandler.bluetoothComDevice)
        connectDeviceTimeoutDispo?.dispose()
    }
    
    public func canCommunicateThroughIB(bluetoothComDeviceHandler: BluetoothComDeviceHandler) {
        let deviceID = bluetoothComDeviceHandler.bluetoothComDevice.deviceID
        let bluetoothMacAddress: String? = bluetoothComDeviceHandler.bluetoothComDevice.bluetoothMacAddress
        MyLog.log(tag: deviceID!,message: "\(TAG)-canCommunicateThroughIB")
        
        pendingConnectDevices.removeAll {
            $0.bluetoothComDevice.deviceID == bluetoothComDeviceHandler.bluetoothComDevice.deviceID
            || $0.bluetoothComDevice.bluetoothMacAddress == bluetoothComDeviceHandler.bluetoothComDevice.bluetoothMacAddress
        }
        
        let handshakedConnectedDevice = handshakedConnectedDevices.first {
            $0.bluetoothComDevice.deviceID == bluetoothComDeviceHandler.bluetoothComDevice.deviceID
            || $0.bluetoothComDevice.bluetoothMacAddress == bluetoothComDeviceHandler.bluetoothComDevice.bluetoothMacAddress
        }
        if(handshakedConnectedDevice == nil) {
            handshakedConnectedDevices.append(bluetoothComDeviceHandler)
        }
        
        bluetoothComDeviceHandler.bluetoothComDevice.tioPeripheral.shallBeSaved = true
        TIOManager.sharedInstance().savePeripherals()
        bleModeMangerCallback.canCommunicateThroughIB(bluetoothComDevice: bluetoothComDeviceHandler.bluetoothComDevice)
    }
    
    public func onConnectFailed(bluetoothComDeviceHandler: BluetoothComDeviceHandler) {
        let deviceID: String = bluetoothComDeviceHandler.bluetoothComDevice.deviceID
        let bluetoothMacAddress: String? = bluetoothComDeviceHandler.bluetoothComDevice.bluetoothMacAddress
        MyLog.log(tag: deviceID, message: "\(TAG)-onConnectFailed")
        
        handshakedConnectedDevices.removeAll {
            $0.bluetoothComDevice.deviceID == bluetoothComDeviceHandler.bluetoothComDevice.deviceID
            || $0.bluetoothComDevice.bluetoothMacAddress == bluetoothComDeviceHandler.bluetoothComDevice.bluetoothMacAddress
        }
        closeSslTcpConnection(bluetoothComDeviceHandler: bluetoothComDeviceHandler)
        bleModeMangerCallback.onFailedConnection(deviceID: deviceID)
    }
    
    public func onDisconnected(bluetoothComDeviceHandler: BluetoothComDeviceHandler, errorMessage: String?) {
        let deviceID: String = bluetoothComDeviceHandler.bluetoothComDevice.deviceID
        MyLog.logAndWriteFile(tag: deviceID, message: "\(TAG)-onDisconnected \(errorMessage)")
        
        closeSslTcpConnection(bluetoothComDeviceHandler: bluetoothComDeviceHandler)
        bleModeMangerCallback.onLostConnection(bluetoothComDevice: bluetoothComDeviceHandler.bluetoothComDevice, message: errorMessage)
        
        handshakedConnectedDevices.removeAll {
            $0.bluetoothComDevice.deviceID == bluetoothComDeviceHandler.bluetoothComDevice.deviceID
            || $0.bluetoothComDevice.bluetoothMacAddress == bluetoothComDeviceHandler.bluetoothComDevice.bluetoothMacAddress
        }
        pendingConnectDevices.removeAll {
            $0.bluetoothComDevice.deviceID == bluetoothComDeviceHandler.bluetoothComDevice.deviceID
            || $0.bluetoothComDevice.bluetoothMacAddress == bluetoothComDeviceHandler.bluetoothComDevice.bluetoothMacAddress
        }
    }
    
    public func onKA(bluetoothComDeviceHandler: BluetoothComDeviceHandler) {
        let deviceID = bluetoothComDeviceHandler.bluetoothComDevice.deviceID
        let bluetoothMacAddress: String? = bluetoothComDeviceHandler.bluetoothComDevice.bluetoothMacAddress
        MyLog.log(tag: deviceID!,message: "\(TAG)-onKA")
        
        pendingConnectDevices.removeAll {
            $0.bluetoothComDevice.deviceID == bluetoothComDeviceHandler.bluetoothComDevice.deviceID
            || $0.bluetoothComDevice.bluetoothMacAddress == bluetoothComDeviceHandler.bluetoothComDevice.bluetoothMacAddress
        }
        
        let handshakedConnectedDevice = handshakedConnectedDevices.first {
            $0.bluetoothComDevice.deviceID == bluetoothComDeviceHandler.bluetoothComDevice.deviceID
            || $0.bluetoothComDevice.bluetoothMacAddress == bluetoothComDeviceHandler.bluetoothComDevice.bluetoothMacAddress
        }
        if(handshakedConnectedDevice == nil) {
            handshakedConnectedDevices.append(bluetoothComDeviceHandler)
            bluetoothComDeviceHandler.bluetoothComDevice.tioPeripheral.shallBeSaved = true
            TIOManager.sharedInstance().savePeripherals()
            bleModeMangerCallback.canCommunicateThroughIB(bluetoothComDevice: bluetoothComDeviceHandler.bluetoothComDevice)
        }
    }
}

// MARK: ScannerCallback
extension BLEModeManager: ScannerCallback {
    public func didNotFound(deviceID: String) {
        MyLog.logAndWriteFile(tag: deviceID, message: "\(TAG)-didNotFound \(deviceID)")
        bleModeMangerCallback.scanDidNotFound(deviceID: deviceID)
        BleScanner.sharedInstance.stopScan()
        
    }
    
    public func blueToothOn() {
        reconnectBondedDevice()
        bleModeMangerCallback.blueToothOn()
    }
    
    public func blueToothOff() {
        onBluetoothOff()
        bleModeMangerCallback.blueToothOff()
    }
    
    public func didFound(peripheral: TIOPeripheral) {
        let deviceID = peripheral.deviceID
        MyLog.log(tag: deviceID, message: "\(TAG)-didFound \(deviceID)- require is:\(manualConnectDeviceId)")
        
        if manualConnectDeviceId == deviceID {
            manualConnectDeviceId = nil
            BleScanner.sharedInstance.stopScan()
            
            connectToDevice(tioPeripheral: peripheral, deviceName: deviceID, timeOut: Constant.CONNECT_DEVICE_TIME_OUT)
        }
        bleModeMangerCallback.scanFound(tioPeripheral: peripheral)
    }
    
}
