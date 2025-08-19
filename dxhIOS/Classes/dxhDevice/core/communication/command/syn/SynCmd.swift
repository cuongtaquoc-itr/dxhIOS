import Foundation

struct SynCmd {
    static func request() -> Data {
        let channelID: UInt8 = ChannelID.USB_SYN.rawValue
        let data = "SYN=0"
        let bytesData = ByteUtils.buildUsbPackageData(data)
        let dataLength = UInt8(bytesData.count)
        let packageHeader = Data([channelID, dataLength])

        return ByteUtils.concatenateTwoByteArray(packageHeader, bytesData)
    }
}





