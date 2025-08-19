import Foundation

class PacketParser {
    private let TAG = "PacketParser"
    private let deviceId: String
    private let packetParserCallback: PacketParserCallback
    
    private var notificationBuffer = ""
    
    
    init(deviceId: String, packetParserCallback: PacketParserCallback) {
        self.deviceId = deviceId
        self.packetParserCallback = packetParserCallback
    }
    
    
    func handleFrameData(frameData: Data) {
        guard let packages = parseFrameDataIntoPackages(pack: frameData) else {
            return
        }
        MyLog.log(tag: deviceId, message: "==packet in frame \(packages.count)", logPriority: 8)
        for p in packages {
            handlePackage(pack: p)
        }
    }
    
    
    private func handlePackage(pack: Data) {
        let channelId = ChannelID(rawValue: pack[0])
        MyLog.log(tag: deviceId, message: "==channelId \(channelId)", logPriority: 8)
        guard let dataLength = PackageUtils.getPackageDataLength(packet: pack) else {
            return
        }
        MyLog.log(tag: deviceId, message: "==dataLength \(dataLength)", logPriority: 8)
        guard let packageData = ByteUtils.subByteArray(src: pack, startPos: 2, num: dataLength)  else {
            return
        }
        MyLog.log(tag: deviceId, message: "==byte \(packageData.toHexString())", logPriority: 9)      
        
        switch (channelId) {
        case .USB_SYN:
            packetParserCallback.onSynPacket(data: packageData)
            break
            
        case .SM_COMMAND:
            let packageStringData = ByteUtils.subByteArray(src: packageData, startPos: 0, num: packageData.count - 1)!.toString()!
            packetParserCallback.onSmCmdPacket(data: packageStringData)
            break
            
        case .INTERNET_BRIDGE :
            packetParserCallback.onIbPacket(data: packageData)
            break
            
        case .STUDY_PROTOCOL:
            packetParserCallback.onSpPacket(data: packageData)
            break
            
        case .SM_NOTIFICATION :
            notificationBuffer += packageData.toString()!
            while(!notificationBuffer.isEmpty && notificationBuffer.firstIndex(of: "\n") != nil){
                if let index = notificationBuffer.firstIndex(of: "\n") {
                    let notiString = String(notificationBuffer[..<index])
                    notificationBuffer.removeSubrange(..<notificationBuffer.index(after: index))
                    packetParserCallback.onSmNotifyPacket(data: String(notiString))
                }
            }
            break
            
        case .ECG_SAMPLE :
            packetParserCallback.onEcgPacket(data: packageData)
            break
            
        case .DEBUG :
            let packageStringData = packageData.toString()!
            MyLog.log(tag: deviceId, message: "==packageStringData \(packageStringData)", logPriority: 8)
            break
            
        default:
            break
        }
    }
    
    
    /**
     * Parse frame data into array list of package
     *
     * Frame data consist of one or many package in sequential order
     */
    private func parseFrameDataIntoPackages(pack: Data)-> [Data]? {
        if pack.isEmpty {
            return nil
        }
        guard let currentPackage = getPackage(pack: pack) else {
            return nil
        }
        guard let remainBytes = ByteUtils.subByteArray(
            src: pack,
            startPos: currentPackage.count,
            num: pack.count - currentPackage.count
        )else {
            return [currentPackage]
        }
        
        guard let remainPackages = parseFrameDataIntoPackages(pack: remainBytes) else {
            return [currentPackage]
        }
        
        var data = [currentPackage]
        for remain in remainPackages {
            data.append(remain)
        }
        return data
    }
    
    private func getPackage(pack: Data)-> Data? {
        guard let dataLength = PackageUtils.getPackageDataLength(packet: pack),
              let packageData = ByteUtils.subByteArray(src: pack, startPos: 2, num: dataLength) else {
            return nil
        }
        
        return ByteUtils.concatenateTwoByteArray(Data([pack[0], pack[1]]), packageData)
    }
}
