struct SmUECGhandler {
    static func parse(packageStringData: String) -> EcgStreamResult {
        let failResult = EcgStreamResult(success: false, ecgConfig: ECGConfig(gain: 0.0, channel: "", sampleRate: 0))
        
        if (packageStringData.contains("OK+\(SmCommand.UECG)=1")) {
            let data = packageStringData.replacingOccurrences(of: "OK+\(SmCommand.UECG)=1,", with: "")
            let message = data.components(separatedBy: (","))
            let channel = message[0]
            guard let samplingRate = Int(message[1]) else {
                return failResult
            }
            guard let gain = Double(message[2]) else {
                return failResult
            }
            return EcgStreamResult(success:true, ecgConfig: ECGConfig(gain: gain, channel: channel, sampleRate: samplingRate))
        }
        return failResult
    }
}
