import Foundation

public struct ECGDataNotiHandler {
    public static func parseECGSample(ecgConfig: ECGConfig, data: Data) -> ECGSample? {
        let channels = convertChannel(channel: ecgConfig.channel)
        
        switch channels.count {
        case 1:
            return parseOneChannel(channels: channels,data: data)
        case 2:
            return parseTwoChannels(channels: channels, data: data)
        case 3:
            return parseThreeChannels(channels: channels, data: data)
        default:
            return nil
        }
    }
    
    private static func convertChannel(channel: String) -> [Channel] {
        var list = [Channel]()
        switch channel {
        case "1": list.append(Channel.CH_1)
        case "2": list.append(Channel.CH_2)
        case "3": list.append(Channel.CH_3)
        case "12": do {
            list.append(Channel.CH_1)
            list.append(Channel.CH_2)
        }
        case "13": do {
            list.append(Channel.CH_1)
            list.append(Channel.CH_3)
        }
        case "23": do {
            list.append(Channel.CH_2)
            list.append(Channel.CH_3)
        }
        case "123":  do {
            list.append(Channel.CH_1)
            list.append(Channel.CH_2)
            list.append(Channel.CH_3)
        }
        case "1234":  do {
            list.append(Channel.CH_1)
            list.append(Channel.CH_2)
            list.append(Channel.CH_3)
            list.append(Channel.CH_4)
        }
        default:
            break
        }
        return list
    }
    
    private static func parseOneChannel(channels: [Channel], data: Data) -> ECGSample? {
        var ch = [Int16]()
        for i in stride(from: 0, to: data.count, by: 2) {
            let sample = data.sub(in: i...i+2)
            guard let value = sample?.int16 else { return nil}
            ch.append(value)
        }
        
        switch channels[0] {
        case .CH_1:
            return ECGSample(ch1: ch, ch2: nil, ch3: nil, ch4: nil)
        case .CH_2:
            return ECGSample(ch1: ch, ch2: nil, ch3: nil, ch4: nil)
        case .CH_3:
            return ECGSample(ch1: ch, ch2: nil, ch3: nil, ch4: nil)
        case .CH_4:
            return nil
        }
    }
    
    private static func parseTwoChannels(channels: [Channel], data: Data) -> ECGSample? {
        var data1 = [Int16]()
        var data2 = [Int16]()
        for i in stride(from: 0, to: data.count, by: 4) {
            let sample1 = data.sub(in: i...i+2)
            let sample2 = data.sub(in: i+2...i+4)
            guard let value1 = sample1?.int16 else { return nil}
            guard let value2 = sample2?.int16 else { return nil}
            data1.append(value1)
            data2.append(value2)
        }
        let chValue1 = channels[0]
        let chValue2 = channels[1]
        if(chValue1 == .CH_1 && chValue2 == .CH_2) {
            return ECGSample(ch1: data1, ch2: data2, ch3: nil, ch4: nil)
        } else if (chValue1 == .CH_1 && chValue2 == .CH_3) {
            return ECGSample(ch1: data1, ch2: nil, ch3: data2, ch4: nil)
        } else {
            return ECGSample(ch1: nil, ch2: data1, ch3: data2, ch4: nil)
        }
    }
    
    private static func parseThreeChannels(channels: [Channel], data: Data) -> ECGSample? {
        var data1 = [Int16]()
        var data2 = [Int16]()
        var data3 = [Int16]()
        for i in stride(from: 0, to: data.count, by: 6) {
            if(i+6 >= data.count){
                continue
            }
            let sample1 = data.sub(in: i...i+2)
            let sample2 = data.sub(in: i+2...i+4)
            let sample3 = data.sub(in: i+4...i+6)
            guard let value1 = sample1?.int16 else { return nil}
            guard let value2 = sample2?.int16 else { return nil}
            guard let value3 = sample3?.int16 else { return nil}
            data1.append(value1)
            data2.append(value2)
            data3.append(value3)
        }
        return ECGSample(ch1: data1, ch2: data2, ch3: data3, ch4: nil)
    }
}
