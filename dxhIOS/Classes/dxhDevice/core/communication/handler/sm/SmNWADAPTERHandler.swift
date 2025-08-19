struct SmNWADAPTERHandler {
    static func parse(packageStringData: String) -> NetworkAdapterType? {
        if (packageStringData.contains("OK+\(SmCommand.NWADAPTER)=\(NetworkAdapterType.USB)")) {
            return NetworkAdapterType.USB
        } else if (packageStringData.contains("OK+\(SmCommand.NWADAPTER)=\(NetworkAdapterType.CELL)")) {
            return  NetworkAdapterType.CELL
        } else {
            return nil
        }
    }
}
