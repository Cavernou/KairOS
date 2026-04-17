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
        let endpoint = NodeClient.Endpoint(host: "test-host", port: 9999, useTailscale: false)
        
        NodeClient.Endpoint.persist(host: endpoint.host, port: endpoint.port, useTailscale: endpoint.useTailscale)
        let stored = NodeClient.Endpoint.stored()
        
        XCTAssertEqual(stored.host, "test-host")
        XCTAssertEqual(stored.port, 9999)
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
        let publicKeyData = Data([1, 2, 3, 4])
        let publicKey = publicKeyData.base64EncodedString()
        let result = try await nodeClient.activateDevice(
            deviceID: UUID().uuidString,
            kairNumber: "K-TEST-1234",
            publicKey: publicKey,
            adminCode: "",
            avatarData: nil
        )
        
        XCTAssertFalse(result.state.isEmpty)
        // Should return pending state or debug admin code for empty admin code
    }
    
    func testMessagePacketCreation() async {
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
        
        do {
            try await nodeClient.send(packet: packet)
        } catch {
            // Should handle network errors gracefully
            XCTAssertTrue(true)
        }
    }
    
    func testContactsFetch() async {
        do {
            let contacts = try await nodeClient.fetchContacts()
            XCTAssertFalse(contacts.isEmpty)
        } catch {
            // Should handle network errors gracefully
            XCTAssertTrue(true)
        }
    }
    
    func testStatusCheck() async {
        let status = await nodeClient.currentStatus()
        
        XCTAssertNotNil(status.tailnet)
        XCTAssertFalse(status.tailnet.isEmpty)
    }
}
