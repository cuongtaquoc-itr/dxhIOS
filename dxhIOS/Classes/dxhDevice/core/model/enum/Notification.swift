enum Notification: String {
    case PREFIX = "NT"
    
    case DEV_STAT
    case SPREADY
    case EVENT_TRIGGERED
    
    static func parseNotification(value: String)-> Notification? {
        if value.contains(Notification.DEV_STAT.rawValue) {
            return Notification.DEV_STAT
        }else if value.contains(Notification.SPREADY.rawValue) {
            return Notification.SPREADY
        }else if value.contains(Notification.EVENT_TRIGGERED.rawValue) {
            return Notification.EVENT_TRIGGERED
        }
        return nil
    }
}
