import Foundation

protocol TCPClientCallback {
    func didTcpConnected()
    func didLostTcpConnection()
    func didReceiveTcpData(data: Data?)
    func connectTcpFailed()
    func tcpTimeout()
}
