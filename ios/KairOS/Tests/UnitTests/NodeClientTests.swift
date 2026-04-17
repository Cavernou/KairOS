import XCTest
import Foundation
@testable import KairOS

@MainActor
final class NodeClientTests: XCTestCase {
    
    var nodeClient: NodeClient!
    
    override func setUp() {
        super.setUp()
        nodeClient = NodeClient()
    }
    
    func testEndpointPersistence() {
        let originalEndpoint = NodeClient.Endpoint.stored()
        let endpoint = NodeClient.Endpoint(host: "test-host", port: 9999, useTailscale: false)
        
        NodeClient.Endpoint.persist(host: endpoint.host, port: endpoint.port, useTailscale: endpoint.useTailscale)
        let stored = NodeClient.Endpoint.stored()
        
        XCTAssertEqual(stored.host, "test-host")
        XCTAssertEqual(stored.port, 9999)
        
        // Reset to original endpoint
        NodeClient.Endpoint.persist(host: originalEndpoint.host, port: originalEndpoint.port, useTailscale: originalEndpoint.useTailscale)
    }
    
    func testDefaultEndpoint() {
        let endpoint = NodeClient.Endpoint.stored()
        
        XCTAssertFalse(endpoint.host.isEmpty)
        XCTAssertGreaterThan(endpoint.port, 0)
    }
    
    func testEndpointEquality() {
        let endpoint1 = NodeClient.Endpoint(host: "test", port: 8080, useTailscale: false)
        let endpoint2 = NodeClient.Endpoint(host: "test", port: 8080, useTailscale: false)
        let endpoint3 = NodeClient.Endpoint(host: "different", port: 8080, useTailscale: false)
        
        XCTAssertEqual(endpoint1, endpoint2)
        XCTAssertNotEqual(endpoint1, endpoint3)
    }
    
    func testActivationResult() async throws {
        let realClient = NodeClient(endpoint: NodeClient.Endpoint(host: "192.168.12.253", port: 8081, useTailscale: false))
        let publicKeyData = Data([1, 2, 3, 4])
        let publicKey = publicKeyData.base64EncodedString()
        let result = try await realClient.activateDevice(
            deviceID: UUID().uuidString,
            kairNumber: "K-3000-0003",
            publicKey: publicKey,
            adminCode: "",
            avatarData: nil
        )
        
        XCTAssertFalse(result.state.isEmpty)
        XCTAssertEqual(result.state, "pending_admin_code")
    }
    
    func testMessagePacketCreation() async throws {
        let realClient = NodeClient(endpoint: NodeClient.Endpoint(host: "192.168.12.253", port: 8081, useTailscale: false))
        let packet = MessagePacket(
            id: UUID().uuidString,
            type: "message",
            senderKair: "K-SEND-1234",
            receiverKair: "K-RECV-5678",
            timestamp: Int64(Date.now.timeIntervalSince1970 * 1000),
            encryptedPayload: "test".data(using: .utf8)!,
            nodeRoute: ["home-node"],
            hasAttachments: false
        )
        
        try await realClient.send(packet: packet)
    }
    
    func testContactsFetch() async throws {
        let realClient = NodeClient(endpoint: NodeClient.Endpoint(host: "192.168.12.253", port: 8081, useTailscale: false))
        let contacts = try await realClient.fetchContacts()
        XCTAssertFalse(contacts.isEmpty)
        // Verify at least the default contacts exist
        XCTAssertGreaterThanOrEqual(contacts.count, 2)
    }
    
    func testStatusCheck() async {
        let status = await nodeClient.currentStatus()
        
        XCTAssertNotNil(status.tailnet)
        XCTAssertFalse(status.tailnet.isEmpty)
    }
}
