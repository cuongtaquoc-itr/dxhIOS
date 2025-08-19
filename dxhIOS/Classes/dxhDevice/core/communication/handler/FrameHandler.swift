import Foundation

struct FrameHandler {
    private static let TAG = "FrameHandler"
    
    static func handle(deviceSequenceNumber: Int, frame: Data) -> FrameParseResult {
        if (isErrorPackage(frame: frame)) {
            MyLog.log(tag: TAG, message: "FrameHandler ErrorPackage")
            let errorType = getErrorType(frame: frame)
            return FrameParseResult(success: false, newDeviceSequenceNumber: -1, frameData: nil, errorType: errorType)
        }
        
        if (!sequenceNumberValid(deviceSequenceNumber: deviceSequenceNumber, frame: frame)) {
            MyLog.log(tag: TAG, message: "FrameHandler Error Sequence Number")
            return FrameParseResult(success: false, newDeviceSequenceNumber: -1, frameData: nil, errorType: nil)
        }
        
        if (!crcFrameValid(frame: frame)) {
            MyLog.log(tag: TAG, message: "FrameHandler Error CRC")
            return FrameParseResult(success: false, newDeviceSequenceNumber: -1, frameData: nil, errorType: nil)
        }
        
        guard let frameData = getFrameData(frame: frame) else {
            return FrameParseResult(success: false, newDeviceSequenceNumber: -1, frameData: nil, errorType: nil)
        }
        
        var newDeviceSequenceNumber: Int
        
        if (isSyncPackage(frame: frame)) {
            newDeviceSequenceNumber = -1
        } else {
            let sequenceNumber = getSequenceNumber(frame: frame) ?? 0
            newDeviceSequenceNumber = FrameUtils.calculateSequenceNumber(oldSequenceNumber: sequenceNumber, dataLength: frameData.count)
        }
        
        return FrameParseResult(success: true, newDeviceSequenceNumber: newDeviceSequenceNumber, frameData: frameData, errorType: nil)
    }
    
    private static func isErrorPackage(frame: Data) -> Bool {
        guard let data = frame.toString() else {
            return true
        }
        return data.contains("ERR=Generic") ||
                data.contains("ERR=InvalidSyncToken") ||
                data.contains("ERR=InvalidSyncRequest") ||
                data.contains("ERR=InvalidChannel") ||
                data.contains("ERR=FrameDataLength") ||
                data.contains("ERR=InvalidCrc") ||
                data.contains("ERR=FrameSequenceNumber")
    }
    
    private static func getErrorType(frame: Data) -> FrameErrorType? {
        guard let data = frame.toString() else {
            return nil
        }
        switch true {
        case data.contains("ERR=Generic"):              return .GENERIC
        case data.contains("ERR=InvalidSyncToken"):     return .INVALID_SYNC_TOKEN
        case data.contains("ERR=InvalidSyncRequest"):   return .INVALID_SYNC_REQUEST
        case data.contains("ERR=InvalidChannel"):       return .INVALID_CHANNEL
        case data.contains("ERR=InvalidCrc"):           return .INVALID_CRC
        case data.contains("ERR=FrameDataLength"):      return .FRAME_DATA_LENGTH
        case data.contains("ERR=FrameSequenceNumber"):  return .FRAME_SEQUENCE_NUMBER
        default: return nil
        }
    }
    
    private static func sequenceNumberValid(deviceSequenceNumber: Int, frame: Data)-> Bool {
        if (isSyncPackage(frame: frame)) {
            return true
        }
        let packageSequenceNumber = getSequenceNumber(frame: frame) ?? 0
        return deviceSequenceNumber == packageSequenceNumber
    }
    
    
    private static func isSyncPackage(frame: Data) -> Bool {
        return frame[0] == 0xFF && frame[1] == 0xFF
    }
    
    private static func crcFrameValid(frame: Data)-> Bool {
        guard let frameDataLength = getFrameDataLength(frame: frame),
              let bytesHeaderAndData = ByteUtils.subByteArray(src: frame, startPos: 0, num: 4 + frameDataLength),
              let bytesCRC = ByteUtils.subByteArray(src: frame, startPos: 4 + frameDataLength, num: 4)
        else{
            return false
        }
        let dataToCalCRC = CRC32MPEG2.paddingDataToAlignedToWord(data: bytesHeaderAndData)
        let calculatedCrc = CRC32MPEG2.calc(data: CRC32MPEG2.reverseByteArray(dataToCalCRC))


        return calculatedCrc == bytesCRC
    }
    
    private static func getFrameData(frame: Data)-> Data? {
        guard let frameDataLength = getFrameDataLength(frame: frame) else {
            return nil
        }
        return ByteUtils.subByteArray(src: frame, startPos: 4, num: frameDataLength)
    }
    
    
    
    
    /**
     * Sequence number is byte 1st 2nd of header
     */
    private static func getSequenceNumber(frame: Data)-> Int? {
        guard let bytesSequence = ByteUtils.subByteArray(src: frame, startPos: 0, num: 2) else {
            return nil
        }
        return Int(bytesSequence.uint16)
    }
    
    /**
     * Frame length is byte 3rd 4th of header
     */
    private static func getFrameDataLength(frame: Data)-> Int? {
        guard let bytesFrameLength =  ByteUtils.subByteArray(src: frame, startPos: 2, num: 2) else {
            return nil
        }
        return parseFrameDataLength(bytesFrameLength: bytesFrameLength)
    }
    
    
    private static func parseFrameDataLength(bytesFrameLength: Data)-> Int {
        return Int(bytesFrameLength.uint16)
 }
    
    
    /**
     * Frame length = frame data length + 4 byte header + 4 byte crc
     * If buffer length > frame length meaning buffer is contain a frame
     */
    static func isContainFrame(buffer: Data) ->  Bool {
        guard let frameDataLength = getFrameDataLength(frame: buffer) else {
            return false
        }
        return buffer.count >= frameDataLength + 8
    }
    
    
    /**
     * If buffer contain a frame, extract it
     * else return null
     */
    static func extractFrameFromBuffer(buffer: Data)-> Data? {
        guard let frameDataLength = getFrameDataLength(frame: buffer)else {
            return nil
        }
        return ByteUtils.subByteArray(src: buffer, startPos: 0, num: frameDataLength + 8)
  }
}
