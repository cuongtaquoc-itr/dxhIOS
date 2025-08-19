public extension TIOPeripheral {
    var deviceID: String {
        if let  advertiseName = self.advertisement?.localName {
            var deviceId = advertiseName
            SupportDevice.allValues.forEach { supportedDevicePrefix in
                deviceId = deviceId.replacingOccurrences(of: supportedDevicePrefix.rawValue, with: "")
            }
            return deviceId
        }
       
        if let peripheralName = self.name {
            var deviceId = peripheralName
            SupportDevice.allValues.forEach { supportedDevicePrefix in
                deviceId = deviceId.replacingOccurrences(of: supportedDevicePrefix.rawValue, with: "")
            }
            return deviceId
        }

        return ""
    }
}
