//
//  File.swift
//
//
//  Created by Nha Banh on 22/7/24.
//

import Foundation
struct FrameBuilder {
    /**
     * Frame = FrameHeader + FrameData + FrameFooter
     * @param sequenceNumber
     * @param packets all packet need to send to device
     * @return
     */
    static func usbBuildFrame(sequenceNumber: Int, packets: [Data])-> Data {
        let frameData = buildFrameData(packets: packets)
        let frameHeader = buildFrameHeader(sequenceNumber: sequenceNumber, dataLength: frameData.count)
        let frameFooter = buildFrameFooter(frameHeader: frameHeader, frameData: frameData)
        let frameHeaderAndData = ByteUtils.concatenateTwoByteArray(frameHeader, frameData)
        return ByteUtils.concatenateTwoByteArray(frameHeaderAndData, frameFooter)
    }
    /**
     * Similar to usbBuildFrame
     * A frame which contains one or multiple USB synchronization packets (channel ID = 255) always has fixed sequence number 65535 (0xFFFF)
     * @param packets all packet need to send to device
     * @return
     */
    static func usbBuildSynFrame(packets: [Data]) -> Data{
        let frameData = buildFrameData(packets: packets)
        let frameHeader = buildFrameHeader(sequenceNumber: -1, dataLength: frameData.count)
        let frameFooter = buildFrameFooter(frameHeader: frameHeader, frameData: frameData)
        let frameHeaderAndData = ByteUtils.concatenateTwoByteArray(frameHeader, frameData)
        return ByteUtils.concatenateTwoByteArray(frameHeaderAndData, frameFooter)
    }
    
    /**
     * Create 4 byte frame header contain 2 byte sequence number and 2 byte data length
     * FrameHeader = SequenceNumber + DataLength (2 + 2 = 4 byte)
     * @param sequenceNumber
     * @param dataLength
     * @return
     * */
    static private func buildFrameHeader(sequenceNumber: Int, dataLength: Int)-> Data {
        let sequenceNumHeader = buildSequenceNumber(sequence: sequenceNumber)
        let dataLengthHeader = buildDataLength(data: dataLength)
        
        return ByteUtils.concatenateTwoByteArray(sequenceNumHeader, dataLengthHeader)
    }
    
    /**
     * Create 2 byte (little endian) sequence number of frame header
     */
    private static func buildSequenceNumber(sequence: Int)->Data {
        if(sequence < 0) {
            return Data(ByteUtils.integerToByteArray(from: Int16(sequence)))
        }
        return Data(ByteUtils.integerToByteArray(from: UInt16(sequence)))
    }
    
    /**
     * Create 2 byte (little endian) data length of frame header
     */
    private static func buildDataLength(data: Int)->Data {
        if(data < 0) {
            return Data(ByteUtils.integerToByteArray(from: Int16(data)))
        }
        return Data(ByteUtils.integerToByteArray(from: UInt16(data)))
    }
    
    /**
     * Create frame data contain all packet in sequential order
     * FrameData = packet0 + packet1 + .... + packetN
     * @param packets
     * @return
     */
    private static func buildFrameData(packets: [Data])->Data {
        var frameData = Data()
        for p in packets {
            frameData += p
        }
        return frameData
    }
    
    /**
     * Create 4 byte frame footer
     * FrameFooter is 4 byte (little endian) CRC32 calculated from frame header and frame data
     * @param frameHeader
     * @param frameData
     * @return
     */
    private static func buildFrameFooter(frameHeader: Data, frameData: Data)->Data {
        let frameHeaderAndData = ByteUtils.concatenateTwoByteArray(frameHeader, frameData)
        let dataToCalCRC = CRC32MPEG2.paddingDataToAlignedToWord(data: frameHeaderAndData)
        let reversedByteArray = CRC32MPEG2.reverseByteArray(dataToCalCRC)
        return CRC32MPEG2.calc(data: reversedByteArray)!
    }
}
