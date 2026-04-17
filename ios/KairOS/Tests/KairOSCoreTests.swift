import XCTest
@testable import KairOS

final class KairOSCoreTests: XCTestCase {
    func testPacketSerializerRoundTrip() throws {
        let packet = MessagePacket(
            id: UUID().uuidString,
            type: "message",
            senderKair: "K-1111-1111",
            receiverKair: "K-2222-2222",
            timestamp: 1_700_000_000,
            encryptedPayload: Data("ping".utf8),
            nodeRoute: ["home-node"],
            hasAttachments: false
        )

        let data = try PacketSerializer.encode(packet)
        let decoded = try PacketSerializer.decode(data)
        XCTAssertEqual(decoded.id, packet.id)
    }
}
