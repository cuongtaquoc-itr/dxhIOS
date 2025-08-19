import CoreBluetooth
public struct DeviceUtils {
    public static func getDeviceFullName(deviceId: String) -> String{
        if(deviceId.contains(SupportDevice.OCTO_BEAT.rawValue)){
            return  deviceId
        }
        return "\(SupportDevice.OCTO_BEAT.rawValue)\(deviceId)"
    }   
    
    public static func getDeviceId(deviceName: String) -> String{
        var deviceId = deviceName
        
        SupportDevice.allValues.forEach {
            deviceId = deviceId.replacingOccurrences(of: $0.rawValue, with: "")
        }
        
        return deviceId
    }
    
    public static func deviceRequireTokenToConnect(deviceName: String) -> Bool {
        return deviceName.hasSuffix(UnSupportDevice.UN_SUPPORT_DEVICE_SUFFIX.rawValue)
    }
}

