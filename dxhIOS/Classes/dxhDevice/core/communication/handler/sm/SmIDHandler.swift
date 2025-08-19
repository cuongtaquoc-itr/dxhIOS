struct SmIDHandler {
    static func parse(packageStringData: String) -> String? {
        if (packageStringData.contains("OK+\(SmCommand.ID)")){
            let data = packageStringData.replacingOccurrences(of: "OK+\(SmCommand.ID)", with: "")
            let message = data.components(separatedBy: (","))
            return message[0].replacingOccurrences(of: "=", with: "")
        }else{
            return nil
        }
    }
}
