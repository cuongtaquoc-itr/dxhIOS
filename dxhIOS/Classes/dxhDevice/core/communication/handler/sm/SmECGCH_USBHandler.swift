struct SmECGCH_USBHandler {
    static func parse(packageStringData: String) -> Bool {
        return packageStringData.contains("OK+\(SmCommand.ECGCH_USB)=")
    }
}
