import XCTest
@testable import KairOS

final class BlackboxTests: XCTestCase {
    func testBlackboxRoundTrip() throws {
        let identity = DeviceIdentity(deviceID: UUID(), kairNumber: "K-1234-5678", status: "active", activationTimestamp: .now)
        let snapshot = CacheSnapshot(contacts: [], messages: [], files: [], memory: [])
        let exported = try BlackboxExporter.export(cache: snapshot, identity: identity, passcode: "1234")
        let restored = try BlackboxImporter.importSnapshot(exported, identity: identity, passcode: "1234")
        XCTAssertEqual(restored.contacts.count, 0)
    }
}
