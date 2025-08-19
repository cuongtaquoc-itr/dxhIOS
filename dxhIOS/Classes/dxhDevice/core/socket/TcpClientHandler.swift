import Foundation
import CocoaAsyncSocket
import Security
import RxSwift

class TcpClientHandler: NSObject, GCDAsyncSocketDelegate {
    private let TAG = "SOCKET_HANDLER"
    private let queue = DispatchQueue(label: "Bluetooth.queue", attributes: .concurrent)
    private var mSocket: GCDAsyncSocket?
    private var secCertificate: SecCertificate?
    private var callback: TCPClientCallback
    private var dispoTimeout: Disposable?
    private var isOpened = false
    
    init(callback: TCPClientCallback) {
        self.callback = callback
        super.init()
    }
    
    public func openTcpConnection() -> Void {
        let timeout = DefaultProtocolData.CONNECTION_TIMEOUT
        let ip =  DefaultProtocolData.ADDRESS
        let port =  DefaultProtocolData.PORT

        let certificate =  DefaultProtocolData.CERTIFICATE
        
        self.secCertificate = self.formatCert(cert: certificate)
        self.mSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue(label: "Bluetooth.queue", attributes: .concurrent))
        do {
            self.startConnectionTimeout(timeout: timeout - 1)
            try self.mSocket?.connect(toHost: ip, onPort: UInt16(port), withTimeout: TimeInterval(timeout))
        } catch let error {
            self.callback.connectTcpFailed()
        }
    }
    
    
    
    public func closeTcpConnection() {
        isOpened = false
        dispoTimeout?.dispose()
        mSocket?.disconnect()
    }
    
    public func sendData(data: Data) {
        queue.sync {
            if (!isTCPSocketOpened()) {
                closeTcpConnection()
                return
            }
            if let socket = self.mSocket {
                socket.write(data, withTimeout: -1, tag: 0)
            }
        }
    }
    
    @objc private func startConnectionTimeout(timeout: Int) {
        dispoTimeout =
        Observable<Int>
            .just(1)
            .delay(.seconds(timeout), scheduler: MainScheduler.instance)
            .subscribe (onNext: {i in
                if(i == timeout){
                    self.callback.connectTcpFailed()
                    self.dispoTimeout?.dispose()
                }
            })
    }
    
    private func formatCert(cert: String) -> SecCertificate {
        let endCert = cert.replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
            .replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
        let data = NSData(base64Encoded: endCert, options:NSData.Base64DecodingOptions.ignoreUnknownCharacters)
        let secCert = SecCertificateCreateWithData(kCFAllocatorDefault, data!)
        return secCert!
    }
    
    private func addAnchorToTrust(trust: SecTrust, certificate: SecCertificate) -> SecTrust {
        let array: NSMutableArray = NSMutableArray()
        
        array.add(certificate)
        
        SecTrustSetAnchorCertificates(trust, array)
        
        return trust
    }
    
    
    func isTCPSocketOpened() -> Bool {
        return isOpened
    }
}

extension TcpClientHandler {
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        sock.startTLS([
            kCFStreamSSLIsServer as String: kCFBooleanFalse,
            GCDAsyncSocketManuallyEvaluateTrust: kCFBooleanTrue,
            GCDAsyncSocketSSLProtocolVersionMin: NSNumber(value: SSLProtocol.tlsProtocol12.rawValue),
            GCDAsyncSocketSSLProtocolVersionMax: NSNumber(value: SSLProtocol.tlsProtocol12.rawValue)
        ])
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        isOpened = false
        callback.didLostTcpConnection()
    }
    
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        callback.didReceiveTcpData(data: data)
        sock.readData(withTimeout: -1, tag: 0)
    }
    
    
    func socket(_ sock: GCDAsyncSocket, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        let myTrust:SecTrust = addAnchorToTrust(trust: trust, certificate: self.secCertificate!)
        var result: SecTrustResultType = SecTrustResultType.unspecified
        let error: OSStatus = SecTrustEvaluate(myTrust, &result)
        
        if (error != noErr) {
            print("Evaluation Failed")
        }
        isOpened = true

        dispoTimeout?.dispose()
        callback.didTcpConnected()
        sock.readData(withTimeout: -1, tag: 0)
        completionHandler(true)
    }
}

