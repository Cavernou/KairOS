import Foundation

enum PacketSerializer {
    static func encode(_ packet: MessagePacket) throws -> Data {
        try JSONEncoder().encode(packet)
    }

    static func decode(_ data: Data) throws -> MessagePacket {
        try JSONDecoder().decode(MessagePacket.self, from: data)
    }
}
