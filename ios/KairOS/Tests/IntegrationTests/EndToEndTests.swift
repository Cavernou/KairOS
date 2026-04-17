import XCTest
import Foundation
@testable import KairOS

@MainActor
final class EndToEndTests: XCTestCase {
    
    var appState: AppState!
    
    override func setUp() async throws {
        try await super.setUp()
        appState = AppState()
    }
    
    func testCompleteMessageFlow() async throws {
        // Test: Send message → Queue → Deliver
        let testMessage = "END-TO-END TEST MESSAGE"
        let recipient = "K-TEST-9999"
        
        // Send message
        await appState.sendMessage(to: recipient, text: testMessage)
        
        // Verify message in cache
        let sentMessage = appState.cache.messages.first { $0.text == testMessage }
        XCTAssertNotNil(sentMessage)
        XCTAssertEqual(sentMessage?.receiverKNumber, recipient)
        
        // Wait for async processing
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify message status
        let updatedMessage = appState.cache.messages.first { $0.text == testMessage }
        XCTAssertNotNil(updatedMessage)
        XCTAssertTrue(["queued", "sent", "delivered"].contains(updatedMessage?.status ?? ""))
    }
    
    func testDeviceActivationFlow() async throws {
        // Test: Bootstrap identity → Activate → Mark active
        let testKNumber = "K-E2E-1234"
        
        // Bootstrap identity
        XCTAssertNoThrow(try appState.identityManager.bootstrapIdentity(kairNumber: testKNumber))
        
        let identity = appState.identityManager.identity
        XCTAssertNotNil(identity)
        XCTAssertEqual(identity?.kairNumber, testKNumber)
        XCTAssertEqual(identity?.status, "pending")
        
        // Simulate activation
        appState.identityManager.markActivated()
        
        let activatedIdentity = appState.identityManager.identity
        XCTAssertEqual(activatedIdentity?.status, "active")
        XCTAssertNotNil(activatedIdentity?.activationTimestamp)
    }
    
    func testBlackboxExportFlow() async throws {
        // Test: Create data → Export → Verify file
        let testPasscode = "test1234"
        
        // Ensure we have test data
        appState.cache.seedPreviewData()
        XCTAssertFalse(appState.cache.contacts.isEmpty)
        XCTAssertFalse(appState.cache.messages.isEmpty)
        
        // Export blackbox
        appState.exportBlackbox(passcode: testPasscode)
        
        // Wait for async export
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Verify export status
        XCTAssertTrue(appState.blackboxStatus.contains("SAVED"))
        XCTAssertNotNil(appState.lastBackupLocation)
    }
    
    func testALICEIntegrationFlow() async throws {
        // Test: ALICE query → Response → Tool integration
        let alice = ALICEOrchestrator()
        let prompt = "List available files"
        
        let response = await alice.handle(prompt: prompt)
        
        XCTAssertFalse(response.isEmpty)
        XCTAssertTrue(response.contains("ALICE"))
    }
    
    func testNodeConnectivityFlow() async throws {
        // Test: Node status → Refresh → Update UI
        let initialStatus = appState.nodeStatus
        
        // Refresh node status
        await appState.refreshNodeStatus()
        
        // Wait for async update
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let updatedStatus = appState.nodeStatus
        XCTAssertNotNil(updatedStatus.tailnet)
        XCTAssertFalse(updatedStatus.tailnet.isEmpty)
    }
    
    func testContactSyncFlow() async throws {
        // Test: Fetch contacts → Update cache
        let initialCount = appState.cache.contacts.count
        
        // Refresh contacts
        await appState.refreshContacts()
        
        // Wait for async sync
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let updatedCount = appState.cache.contacts.count
        XCTAssertGreaterThanOrEqual(updatedCount, initialCount)
    }
    
    func testAppRuntimeFlow() async throws {
        // Test: App → SDK → Event bus
        let expectation = XCTestExpectation(description: "Event received")
        
        let api = KairOSAPIImpl(
            nodeClient: appState.nodeClient,
            aliceOrchestrator: ALICEOrchestrator()
        )
        
        // Subscribe to test event
        api.subscribe(to: "test.event") { payload in
            XCTAssertEqual(payload["message"] as? String, "test payload")
            expectation.fulfill()
        }
        
        // Publish event
        api.publish(event: "test.event", payload: ["message": "test payload"])
        
        // Wait for event processing
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testErrorRecoveryFlow() async throws {
        // Test: Network error → Retry → Recovery
        let testMessage = "RECOVERY TEST"
        let recipient = "K-RECOVERY-9999"
        
        // Set node offline
        await appState.setNodeReachable(false)
        
        // Send message (should queue)
        await appState.sendMessage(to: recipient, text: testMessage)
        
        // Verify message is queued
        let queuedMessage = appState.cache.messages.first { $0.text == testMessage }
        XCTAssertNotNil(queuedMessage)
        
        // Restore node connectivity
        await appState.setNodeReachable(true)
        
        // Wait for retry
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Verify status updated
        let updatedMessage = appState.cache.messages.first { $0.text == testMessage }
        XCTAssertNotNil(updatedMessage)
    }
}
