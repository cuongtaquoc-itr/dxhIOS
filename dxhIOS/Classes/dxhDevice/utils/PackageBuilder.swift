import Foundation

struct PackageBuilder {
    
    /**
     * Build 1 of multiple packet from given data
     * Depend on data length, if data length larger than MAX_PACKET_DATA_SIZE, it will be split into multiple packets
     * Package = ChannelId(1 byte) + Data length(1 byte) + data
     */
    
    static func usbBuildPackages(channelID: ChannelID, data: Data)-> [Data] {
        if(data.count <= Constant.MAX_PACKET_DATA_SIZE ){
            return [PackageBuilder.usbBuildPackage(channelID: channelID, data: data)]
        }
        var packages: [Data] = []
        var buffer = Data(data)
        
        while(!buffer.isEmpty){
            let packet = buffer.prefix(Constant.MAX_PACKET_DATA_SIZE)
            packages.append(PackageBuilder.usbBuildPackage(channelID: channelID, data:  packet))
            buffer = buffer.dropFirst(Constant.MAX_PACKET_DATA_SIZE)
        }
        
        return packages
    }
    
    /**
     * Build 1 packet from given data
     * Data length must be smaller or equal MAX_PACKET_DATA_SIZE
     * Package = ChannelId(1 byte) + Data length(1 byte) + data
     */
    static func usbBuildPackage(channelID: ChannelID, data: Data) -> Data {
        let dataLength: UInt8 = UInt8(data.count)
        let header = Data([channelID.rawValue, dataLength])
        return ByteUtils.concatenateTwoByteArray(header, data)
    }
}
