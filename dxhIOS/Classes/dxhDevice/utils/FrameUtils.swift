class FrameUtils {
    static func calculateSequenceNumber(oldSequenceNumber: Int, dataLength: Int) -> Int {
        return (dataLength + oldSequenceNumber) % (Constant.MAX_SEQUENCE_NUMBER + 1)
    }
}
