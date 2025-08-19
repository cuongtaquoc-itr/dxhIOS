import Foundation

struct SmUECG {
    static func request(enable: Bool) -> Data {
        let channelID: UInt8 = ChannelID.SM_COMMAND.rawValue
        var data = ""
        if enable {
            data = "SM+\(SmCommand.UECG)=1"
        } else {
            data = "SM+\(SmCommand.UECG)=0"
        }
        let bytesData = ByteUtils.buildUsbPackageData(data)
        let dataLength = UInt8(bytesData.count)
        let packageHeader = Data([channelID, dataLength])

        return ByteUtils.concatenateTwoByteArray(packageHeader, bytesData)
    }
}
