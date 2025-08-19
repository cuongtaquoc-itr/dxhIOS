import Foundation

public extension Data {
    enum ByteOrder {
        case BIG_ENDIAN
        case LITTLE_ENDIAN
    }
    init<T>(fromArray values: [T]) {
        var values = values
        self.init(buffer: UnsafeBufferPointer(start: &values, count: values.count))
    }
    func sub(in range: ClosedRange<Index>) -> Data? {
        let startPos = range.lowerBound
        let num = range.upperBound - range.lowerBound + 1

        if (startPos < 0 || num <= 0) {
            return nil
        }

        var endPos = 0

        if (startPos + num >= self.count) {
            endPos = self.count
        } else {
            endPos = startPos + num
        }
        return subdata(in: startPos ..< endPos)
    }
    func toString() -> String? {
        return String(decoding: self, as: UTF8.self)
    }
    var uint32: UInt32 {
        withUnsafeBytes { $0.load(as: UInt32.self) }
    }
    var uint16: UInt16 {
        withUnsafeBytes { $0.load(as: UInt16.self) }
    }
    var int16: Int16 {
        withUnsafeBytes { $0.load(as: Int16.self) }
    }
    var uint8: UInt8 {
        withUnsafeBytes { $0.load(as: UInt8.self) }
    }
}


extension Sequence where Element: AdditiveArithmetic {
    /// Returns the total sum of all elements in the sequence
    func sum() -> Element { reduce(.zero, +) }
}

extension Collection where Element: BinaryInteger {
    /// Returns the average of all elements in the array
    func average() -> Element { isEmpty ? .zero : sum() / Element(count) }
    /// Returns the average of all elements in the array as Floating Point type
    func average<T: FloatingPoint>() -> T { isEmpty ? .zero : T(sum()) / T(count) }
}

extension Collection where Element: BinaryFloatingPoint {
    /// Returns the average of all elements in the array
    func average() -> Element { isEmpty ? .zero : Element(sum()) / Element(count) }
}
