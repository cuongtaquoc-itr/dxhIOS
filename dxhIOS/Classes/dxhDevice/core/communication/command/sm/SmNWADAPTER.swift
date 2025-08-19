import Foundation

struct SmNWADAPTER {
    static func request(type: NetworkAdapterType) -> Data {
        let channelID: UInt8 = ChannelID.SM_COMMAND.rawValue
        let data: String
        switch type {
        case .CELL:
            data = "SM+\(SmCommand.NWADAPTER)=\(NetworkAdapterType.CELL.rawValue)"
        case .USB:
            data = "SM+\(SmCommand.NWADAPTER)=\(NetworkAdapterType.USB.rawValue)"
        }
        let bytesData = ByteUtils.buildUsbPackageData(data)
        let dataLength = UInt8(bytesData.count)
        let packageHeader = Data([channelID, dataLength])

        return ByteUtils.concatenateTwoByteArray(packageHeader, bytesData)
    }
}
