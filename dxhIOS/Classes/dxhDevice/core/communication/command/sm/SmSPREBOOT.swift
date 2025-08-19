import Foundation

struct SmSPREBOOT {
    static func request() -> Data {
        let channelID: UInt8 = ChannelID.SM_COMMAND.rawValue
        let data: String = "SM+\(SmCommand.SPREBOOT)"
        let bytesData = ByteUtils.buildUsbPackageData(data)
        let dataLength = UInt8(bytesData.count)
        let packageHeader = Data([channelID, dataLength])
        
        return ByteUtils.concatenateTwoByteArray(packageHeader, bytesData)
    }
}
