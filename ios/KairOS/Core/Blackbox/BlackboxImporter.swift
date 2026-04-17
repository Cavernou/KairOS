import Foundation

enum BlackboxImporter {
    static func importSnapshot(_ data: Data, identity: DeviceIdentity, passcode: String) throws -> CacheSnapshot {
        let envelope = try JSONDecoder().decode(BlackboxEnvelope.self, from: data)
        let salt = Data(identity.deviceID.uuidString.utf8)
        let key = CryptoService.deriveBlackboxKey(from: passcode, salt: salt)

        guard let encrypted = Data(base64Encoded: envelope.payload) else {
            throw NSError(domain: "BlackboxImporter", code: 1)
        }

        let decrypted = try CryptoService.decrypt(encrypted, using: key)
        return try JSONDecoder().decode(CacheSnapshot.self, from: decrypted)
    }
}
