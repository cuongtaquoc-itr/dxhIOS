struct SmTCPSERVERHandler {
    static func parse(packageStringData: String) -> TCPSERVERResult {
        if (packageStringData.contains("OK+\(SmCommand.TCPSERVER)")){
            let data = packageStringData.replacingOccurrences(of: "OK+\(SmCommand.TCPSERVER)", with: "")
            let message = data.components(separatedBy: (","))
            let address = message[0].replacingOccurrences(of: "=", with: "")
            let port = Int(message[1]) ?? DefaultProtocolData.PORT
           
            return TCPSERVERResult(address: address, port: port)
        }else{
            return TCPSERVERResult(address: DefaultProtocolData.ADDRESS, port: DefaultProtocolData.PORT)
        }
    }
}
