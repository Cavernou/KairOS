import Combine
import CryptoKit
import Foundation

@MainActor
final class IdentityManager: ObservableObject {
    @Published private(set) var identity: DeviceIdentity?

    private let privateKeyAccount = "kairos.device.privateKey"

    var isRegistered: Bool {
        return identity?.status == "active"
    }

    func bootstrapIdentity(kairNumber: String) throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        try KeychainWrapper.save(privateKey.rawRepresentation, account: privateKeyAccount)
        identity = DeviceIdentity(
            deviceID: UUID(),
            kairNumber: kairNumber,
            status: "pending",
            activationTimestamp: nil
        )
    }

    func publicKeyData() -> Data? {
        guard
            let data = KeychainWrapper.load(account: privateKeyAccount),
            let privateKey = try? Curve25519.Signing.PrivateKey(rawRepresentation: data)
        else {
            return nil
        }
        return privateKey.publicKey.rawRepresentation
    }

    func markActivated() {
        guard let current = identity else { return }
        identity = DeviceIdentity(
            deviceID: current.deviceID,
            kairNumber: current.kairNumber,
            status: "active",
            activationTimestamp: .now
        )
    }

    func loadIdentity() {
        // Try to load existing identity from keychain
        guard
            let data = KeychainWrapper.load(account: privateKeyAccount),
            let _ = try? Curve25519.Signing.PrivateKey(rawRepresentation: data)
        else {
            identity = nil
            return
        }
        // TODO: Load full identity data from keychain including status
        // For now, just check if we have a key
    }
}
