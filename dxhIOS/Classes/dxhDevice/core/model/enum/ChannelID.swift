enum ChannelID: UInt8 {
    case SM_COMMAND = 0x00
    case SM_NOTIFICATION = 0x01
    case KEEP_ALIVE = 0x02
    case ECG_SAMPLE = 0x03
    case ACC_SAMPLE = 0x04
    case TMP_SAMPLE = 0x05
    case DEBUG = 0x06
    case INTERNET_BRIDGE = 0x07
    case STUDY_PROTOCOL = 0x08
    case USB_SYN = 0xFF
}
