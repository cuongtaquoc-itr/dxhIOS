import Foundation

struct SmID {
    static func request() -> Data {
        let channelID: UInt8 = ChannelID.SM_COMMAND.rawValue
        let data = "SM+\(SmCommand.ID)?"
        let bytesData = ByteUtils.buildUsbPackageData(data)
        let dataLength = UInt8(bytesData.count)
        let packageHeader = Data([channelID, dataLength])

        return ByteUtils.concatenateTwoByteArray(packageHeader, bytesData)
    }
}





