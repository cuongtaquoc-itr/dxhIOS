struct EventTriggeredNotiHandler {
    static func handle(dxhDevice: DXHDevice, data: String) {
        let eventTime = data.replacingOccurrences(of: "\(Notification.PREFIX.rawValue)+\(Notification.EVENT_TRIGGERED.rawValue)=", with: "")
        dxhDevice.mctInstance = MCTInstance(triggerTime: Int64(eventTime)!)
        dxhDevice.deviceInfoUpdateCallback.newMctEvent(dxhDevice: dxhDevice)
    }
}
