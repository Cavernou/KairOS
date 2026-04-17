import CommonCrypto
import CryptoKit
import Foundation

enum CryptoService {
    static func randomKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    static func encrypt(_ plaintext: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(plaintext, using: key)
        return sealedBox.combined ?? Data()
    }

    static func decrypt(_ ciphertext: Data, using key: SymmetricKey) throws -> Data {
        let box = try AES.GCM.SealedBox(combined: ciphertext)
        return try AES.GCM.open(box, using: key)
    }

    static func deriveBlackboxKey(from passcode: String, salt: Data) -> SymmetricKey {
        let keyLength = 32
        var derived = Data(repeating: 0, count: keyLength)
        derived.withUnsafeMutableBytes { derivedBytes in
            salt.withUnsafeBytes { saltBytes in
                _ = CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    passcode,
                    passcode.utf8.count,
                    saltBytes.bindMemory(to: UInt8.self).baseAddress,
                    salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    100_000,
                    derivedBytes.bindMemory(to: UInt8.self).baseAddress,
                    keyLength
                )
            }
        }
        return SymmetricKey(data: derived)
    }
}
