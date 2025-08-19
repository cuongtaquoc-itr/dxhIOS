import Foundation
struct SmEVENTCONFIRMED {
    static func request(eventTime: Int64, symptom: [Int]) -> Data {
        let channelID: UInt8 = ChannelID.SM_COMMAND.rawValue
        let data = buildData(eventTime: eventTime, symptom: symptom)
        let bytesData = ByteUtils.buildUsbPackageData(data)
        let dataLength = UInt8(bytesData.count)
        let packageHeader = Data([channelID, dataLength])
        return ByteUtils.concatenateTwoByteArray(packageHeader, bytesData)
    }
    private static func buildData(eventTime: Int64, symptom: [Int])-> String {
        let cmd = "SM+\(SmCommand.EVENTCONFIRMED.rawValue)="
        let time = "\(eventTime)"
        let symptomStr = Array(symptom.prefix(5)).map{"\($0)"}.joined(separator:",")
        let data = "\(cmd),\(time),\(symptomStr)"
        return data
    }
}

