enum SmCommand: String {
    case ID
    case NWADAPTER
    case MODEMREBOOT
    case SPREBOOT
    case UECG
    case ECGCH_USB
    case EVENTCONFIRMED
    case TCPSERVER
    
    static func parseCommand(value: String) -> SmCommand? {
        if value.contains(SmCommand.ID.rawValue) {
            return SmCommand.ID
        } else if value.contains(SmCommand.NWADAPTER.rawValue){
            return SmCommand.NWADAPTER
        }else if value.contains(SmCommand.MODEMREBOOT.rawValue){
            return SmCommand.MODEMREBOOT
        }else if value.contains(SmCommand.SPREBOOT.rawValue){
            return SmCommand.SPREBOOT
        }else if value.contains(SmCommand.UECG.rawValue){
            return SmCommand.UECG
        }else if value.contains(SmCommand.ECGCH_USB.rawValue){
            return SmCommand.ECGCH_USB
        }else if value.contains(SmCommand.EVENTCONFIRMED.rawValue){
            return SmCommand.EVENTCONFIRMED
        }else if value.contains(SmCommand.TCPSERVER.rawValue){
            return SmCommand.TCPSERVER
        }
        return nil
    }
}
