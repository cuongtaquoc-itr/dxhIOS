class TCPConnection {
    var id: UInt8!
    var authMode: SSLAuthMode!
    var serverCAId: UInt8!
    var clientCAId: UInt8!
    var clientPrivateKeyId: UInt8!
    var isSSLEnable: Bool!
    
    init(id: UInt8, authMode: SSLAuthMode, serverCAId: UInt8, clientCAId: UInt8, clientPrivateKeyId: UInt8) {
        self.id = id
        self.authMode = authMode
        self.serverCAId = serverCAId
        self.clientCAId = clientCAId
        self.clientPrivateKeyId = clientPrivateKeyId
    }
    
    func paste(connection: TCPConnection){
        self.id = connection.id
        self.authMode = connection.authMode
        self.serverCAId = connection.serverCAId
        self.clientCAId = connection.clientCAId
        self.clientPrivateKeyId = connection.clientPrivateKeyId
    }
}
