import Foundation

struct FrameParseResult {
    let success: Bool
    let newDeviceSequenceNumber: Int
    let frameData: Data?
    let errorType: FrameErrorType?
}
