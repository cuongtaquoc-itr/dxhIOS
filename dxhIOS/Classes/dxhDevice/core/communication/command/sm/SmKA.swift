import Foundation

struct SmKA {
    static func request() -> Data {
        let channelID: UInt8 = ChannelID.KEEP_ALIVE.rawValue
        let dataLength: UInt8 = 0x00
        
        return Data([channelID, dataLength])
    }
}





