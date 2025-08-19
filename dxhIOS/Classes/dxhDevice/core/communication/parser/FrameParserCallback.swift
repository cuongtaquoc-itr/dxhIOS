import Foundation

protocol FrameParserCallback {
    func onNewFrame(data: Data)
    func onError(error: String)
}
