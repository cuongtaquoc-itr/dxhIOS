import Foundation

struct PackageUtils {
    /**
     * Package length is 1st unsigned-byte of data
     */
    static func getPackageDataLength(packet: Data) -> Int? {
        return Int(Data([packet[1]]).uint8)
    }
}
