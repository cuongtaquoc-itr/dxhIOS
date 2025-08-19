struct DevStatNotiHandler {
    static func handle(dxhDevice: DXHDevice, notiString: String) {
        var notiContentString = notiString.replacingOccurrences(of: "\(Notification.PREFIX.rawValue)+\(Notification.DEV_STAT.rawValue)=", with: "")
        notiContentString = notiContentString.replacingOccurrences(of: "??", with: "")
        let contents = notiContentString.components(separatedBy: (";"))
        contents.forEach { it in
            if (it.contains("battLevel=")) {
                let value = it.replacingOccurrences(of: "battLevel=", with: "")
                dxhDevice.battLevel = Int(value) ?? 0
            } else if (it.contains("battStatus=")) {
                let value = it.replacingOccurrences(of: "battStatus=", with: "")
                dxhDevice.battLow = Int(value) == 1
                dxhDevice.battCharging = Int(value) == 2
            } else if (it.contains("leadStatus=")) {
                guard let value = Bool(it.replacingOccurrences(of: "leadStatus=",  with: "")) else {
                    return
                }
                dxhDevice.leadStatus = LeadStatus(RAConnected: value, LAConnected: value, LLConnected: value)
            } else if (it.contains("studyStatus=")) {
                let value = it.replacingOccurrences(of: "studyStatus=", with: "")
                dxhDevice.studyStatus = value
            } else if (it.contains("apiVersion=")) {
                guard let value = Int(it.replacingOccurrences(of: "apiVersion=", with:  "")) else {
                    return
                }
                dxhDevice.apiVersion = value
            }else if (it.contains("battTime=")) {
                guard let value = Int(it.replacingOccurrences(of: "battTime=", with:  "")) else {
                    return
                }
                dxhDevice.chargingRemaining = value
            }
        }
    }
}
