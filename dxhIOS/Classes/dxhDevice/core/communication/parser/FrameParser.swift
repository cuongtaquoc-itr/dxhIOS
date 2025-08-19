import Foundation

class FrameParser {
    private let TAG = "FrameParser"
    private var buffer = Data()
    private let frameParserCallback: FrameParserCallback
    
    init(frameParserCallback: FrameParserCallback) {
        self.frameParserCallback = frameParserCallback
    }
    
    func addData(data: Data)  {
        if(data.count == 3 && data[0] == 0x2b && data[1] == 0x2b && data[2] == 0x2b){
            return
        }
        buffer = buffer + data

        extractFrameIfAny()
    }

    private func extractFrameIfAny() {
        if (!FrameHandler.isContainFrame(buffer: buffer)) {
            return
        }
        guard let frame = FrameHandler.extractFrameFromBuffer(buffer: buffer) else {
            return
        }
        buffer = ByteUtils.subByteArray(src: buffer, startPos: frame.count, num: buffer.count - frame.count)!
        frameParserCallback.onNewFrame(data: frame)
    }
    
    func reset() {
        buffer = Data()
    }
}
