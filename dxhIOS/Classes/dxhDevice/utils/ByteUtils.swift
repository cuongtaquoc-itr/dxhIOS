import Foundation
public struct ByteUtils {
    public static func buildUsbPackageData(_ string: String) -> Data {
        let data = stringToByteArray(string)
        return concatenateTwoByteArray(Data(data), Data([0x00]))
    }
    public static func toData(arrayInt16: [Int16]) -> Data {
        var data = Data()
        arrayInt16.forEach {
            data.append(contentsOf: withUnsafeBytes(of: $0.bigEndian){ Data($0) } )
        }
        return data
    }
    public static func subByteArray(src: Data, startPos: Int, num: Int) -> Data? {
        if startPos < 0 || num < 0 {
            return nil
        }
        if num == 0 {
            return Data()
        }
        let endPos: Int = (startPos + num > src.count) ? src.count : (startPos + num)

        return Data(src[startPos..<endPos])
    }
    public static func concatenateTwoByteArray(_ firstByteArray: Data, _ secondByteArray: Data) -> Data {
        if firstByteArray.isEmpty {
            return secondByteArray
        }
        if secondByteArray.isEmpty {
            return firstByteArray
        }

        return Data(firstByteArray + secondByteArray)
    }
    public static func stringToByteArray(_ string: String) -> [UInt8] {
        return Array(string.utf8)
    }
    public static func integerToByteArray<T>(from value: T) -> [UInt8] where T: FixedWidthInteger {
        withUnsafeBytes(of: value.littleEndian, Array.init)
    }
}
