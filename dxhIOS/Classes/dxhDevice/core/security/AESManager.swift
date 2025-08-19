import Foundation
import CryptoSwift

class AESManager: NSObject {
    var deviceName: String
    var key: Array <UInt8>
    var iv: Array <UInt8>
    
    init(deviceName: String) {
        self.deviceName = DeviceUtils.getDeviceFullName(deviceId: deviceName)
        let hashedMacAddr = (Data(self.deviceName.bytes).sha256())
        iv = [UInt8] (hashedMacAddr[0..<16])
        key = [UInt8] (hashedMacAddr[16..<32])

    }
    
    
    func encrypt(data: [UInt8]) -> [UInt8]? {
        do {
            let encrypted = try AES(key: key, blockMode: CTR(iv: iv), padding: .noPadding).encrypt(data)
            return encrypted
        } catch {
            print(error)
            return nil
        }
    }
    
    func decrypt(bytes: [UInt8]) -> [UInt8]? {
        do {
            let decrypted = try AES(key: key, blockMode: CTR(iv: iv), padding: .noPadding).decrypt(bytes)
           return decrypted
        } catch {
            print(error)
            return nil
        }
    }

}
