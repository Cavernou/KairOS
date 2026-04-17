import CryptoKit
import Foundation

struct BlackboxEnvelope: Codable {
    let formatVersion: String
    let createdAt: String
    let deviceID: String
    let kairNumber: String
    let encryptionScheme: String
    let integrityHash: String
    let payload: String
}

struct BlackboxExportArtifact {
    let filename: String
    let url: URL
    let checksum: String
    let size: Int
}

enum BlackboxExporter {
    static func export(cache: CacheSnapshot, identity: DeviceIdentity, passcode: String) throws -> Data {
        let payload = try JSONEncoder().encode(cache)
        let salt = Data(identity.deviceID.uuidString.utf8)
        let key = CryptoService.deriveBlackboxKey(from: passcode, salt: salt)
        let encrypted = try CryptoService.encrypt(payload, using: key)
        let hash = Data(SHA256.hash(data: encrypted)).base64EncodedString()
        let envelope = BlackboxEnvelope(
            formatVersion: "1.0",
            createdAt: ISO8601DateFormatter().string(from: .now),
            deviceID: identity.deviceID.uuidString,
            kairNumber: identity.kairNumber,
            encryptionScheme: "AES-256-GCM",
            integrityHash: hash,
            payload: encrypted.base64EncodedString()
        )
        return try JSONEncoder().encode(envelope)
    }

    static func exportToDocuments(cache: CacheSnapshot, identity: DeviceIdentity, passcode: String) throws -> BlackboxExportArtifact {
        let data = try export(cache: cache, identity: identity, passcode: passcode)
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "BlackboxExporter", code: 2, userInfo: [NSLocalizedDescriptionKey: "Documents directory unavailable"])
        }

        let blackboxDirectory = documentsDirectory.appendingPathComponent("Blackbox", isDirectory: true)
        try fileManager.createDirectory(at: blackboxDirectory, withIntermediateDirectories: true)

        let stamp = ISO8601DateFormatter.fileSafe.string(from: .now)
        let filename = "KairOS-\(identity.kairNumber)-\(stamp).kairbox"
        let url = blackboxDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)

        let checksum = Data(SHA256.hash(data: data)).base64EncodedString()
        return BlackboxExportArtifact(
            filename: filename,
            url: url,
            checksum: checksum,
            size: data.count
        )
    }
}

private extension ISO8601DateFormatter {
    static let fileSafe: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter
    }()
}
