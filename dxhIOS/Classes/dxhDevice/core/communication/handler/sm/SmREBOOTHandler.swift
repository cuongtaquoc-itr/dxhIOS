struct SmREBOOTHandler {
    static func parse(packageStringData: String) -> Bool {
        return packageStringData.contains("OK+\(SmCommand.MODEMREBOOT)")
    }
}
