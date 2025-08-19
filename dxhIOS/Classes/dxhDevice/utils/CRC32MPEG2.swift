import Foundation

/**************************************************************************
 *  Using table lookup
 *  Reference: https://crccalc.com/
 **************************************************************************/

struct CRC32MPEG2 {
    static func calc(data: Data) -> Data? {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            var current = UInt32(byte) << 24
            for _ in 0..<8 {
                let bit = (crc ^ current) & 0x80000000
                crc = (crc << 1) ^ (bit != 0 ? 0x04C11DB7 : 0)
                current <<= 1
            }
        }
        // MPEG-2: no final XOR, no reflection
        let crcValue = crc
        var little = crcValue.littleEndian
        return withUnsafeBytes(of: &little) { Data($0) }
    }
    
    static func paddingDataToAlignedToWord(data: Data) -> Data {
        var temp = Data()
        temp.append(contentsOf: data)
        while (temp.count % 4 != 0) {
            temp.append(0xFF)
        }
        return temp
    }

    /**
     * Input data length must be aligned to word (4 bytes)
     * Revers order of bytes in each word
     * @param byteArray
     * @return byteArray with order of byte in word revers but order of word is not change
     * */
    static func reverseByteArray(_ data: Data) -> Data {
        var newByteArray = Data()
        
        let words = stride(from: 0, to: data.count, by: 4).map {
            Array(data[$0..<min($0 + 4, data.count)])
        }
        
        for word in words {
            newByteArray.append(contentsOf: word.reversed())
        }
        
        return newByteArray
    }
}
