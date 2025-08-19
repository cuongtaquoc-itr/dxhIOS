struct SynHandler {
    static func parse(
        packageStringData: String,
        onSchemaVersion: (_ schemaVersion: Int) -> Void,
        onDeviceSequenceNumber: (_ deviceSequenceNumber: Int) -> Void,
        onRandomKey: (_ randomKey: String) -> Void
    ) {
        if (packageStringData.contains("SYN=")) {
            let data = packageStringData.replacingOccurrences(of: "SYN=", with: "")
            let message = data.components(separatedBy: (","))
            let schemaVersion = Int(message[0])!
            let deviceSequenceNumber = Int(message[1])!
            
            onSchemaVersion(schemaVersion)
            onDeviceSequenceNumber(deviceSequenceNumber)
        } else if (packageStringData.contains("KEY=")) {
            let data = packageStringData.replacingOccurrences(of: "KEY=", with: "")
            let message = data.components(separatedBy: (","))
            let randomKey = message[0]
            
            onRandomKey(randomKey)
        }
    }
}


