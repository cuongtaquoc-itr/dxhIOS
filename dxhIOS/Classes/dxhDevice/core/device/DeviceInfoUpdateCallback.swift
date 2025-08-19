public protocol DeviceInfoUpdateCallback {
    func tcpConnected(dxhDevice: DXHDevice)
    func tcpDisconnected(dxhDevice: DXHDevice)
    
    func updateInfo(dxhDevice: DXHDevice)
    
    func updateECGConfig(dxhDevice: DXHDevice)
    func updateECGData(dxhDevice: DXHDevice)
    
    func newMctEvent(dxhDevice: DXHDevice)
}
