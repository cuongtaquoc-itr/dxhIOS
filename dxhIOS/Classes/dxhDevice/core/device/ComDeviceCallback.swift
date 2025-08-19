import Foundation

public protocol ComDeviceCallback {
    func onRawData(data: Data)
    func onKA()
    func onError(error: String)
}
