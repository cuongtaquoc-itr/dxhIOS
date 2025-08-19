import Foundation

struct SmECGCH_USB {
    static func request(channel: String = "123") -> Data {
        let channelID: UInt8 = ChannelID.SM_COMMAND.rawValue
        let data = "SM+\(SmCommand.ECGCH_USB)=\(channel)"
        let bytesData = ByteUtils.buildUsbPackageData(data)
        let dataLength = UInt8(bytesData.count)
        let packageHeader = Data([channelID, dataLength])

        return ByteUtils.concatenateTwoByteArray(packageHeader, bytesData)
    }
}
