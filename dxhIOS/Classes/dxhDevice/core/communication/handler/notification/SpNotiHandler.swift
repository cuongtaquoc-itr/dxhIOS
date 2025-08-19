struct SpNotiHandler {
    static func handle(dxhDevice: DXHDevice, data: String) {
        if (data == "\(Notification.PREFIX.rawValue)+\(Notification.SPREADY.rawValue)=1") {
            dxhDevice.closeTcpConnection()
            dxhDevice.openTcpConnectionWithRetry()
        } else if (data == "\(Notification.PREFIX.rawValue)+\(Notification.SPREADY.rawValue)=0") {
            dxhDevice.closeTcpConnectionAndStopRetry()
        }
    }
}
