import Foundation

protocol PacketParserCallback {
    func onSynPacket(data: Data)
    func onIbPacket(data: Data)
    func onSpPacket(data: Data)
    func onSmCmdPacket(data: String)
    func onSmNotifyPacket(data: String)
    func onEcgPacket(data: Data)
}
