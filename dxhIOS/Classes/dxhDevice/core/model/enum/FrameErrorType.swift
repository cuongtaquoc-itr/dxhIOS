enum FrameErrorType: String {
    case GENERIC
    case INVALID_SYNC_TOKEN
    case INVALID_SYNC_REQUEST
    case INVALID_CHANNEL
    case INVALID_CRC
    case FRAME_DATA_LENGTH
    case FRAME_SEQUENCE_NUMBER
}
