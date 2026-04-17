import XCTest
import CryptoKit
@testable import KairOS

final class CryptoServiceTests: XCTestCase {
    
    func testEncryptDecryptRoundtrip() throws {
        let plaintext = "TEST MESSAGE FOR KAIROS".data(using: .utf8)!
        let key = CryptoService.randomKey()
        
        let encrypted = try CryptoService.encrypt(plaintext, using: key)
        let decrypted = try CryptoService.decrypt(encrypted, using: key)
        
        XCTAssertEqual(decrypted, plaintext)
    }
    
    func testBlackboxKeyDerivation() throws {
        let passcode = "test1234"
        let salt = "test-salt".data(using: .utf8)!
        
        let key1 = CryptoService.deriveBlackboxKey(from: passcode, salt: salt)
        let key2 = CryptoService.deriveBlackboxKey(from: passcode, salt: salt)
        
        XCTAssertEqual(key1.withUnsafeBytes { Data($0) }, key2.withUnsafeBytes { Data($0) })
    }
    
    func testDifferentPasscodesProduceDifferentKeys() throws {
        let passcode1 = "pass123"
        let passcode2 = "pass456"
        let salt = "test-salt".data(using: .utf8)!
        
        let key1 = CryptoService.deriveBlackboxKey(from: passcode1, salt: salt)
        let key2 = CryptoService.deriveBlackboxKey(from: passcode2, salt: salt)
        
        XCTAssertNotEqual(key1.withUnsafeBytes { Data($0) }, key2.withUnsafeBytes { Data($0) })
    }
    
    func testRandomKeyGeneration() {
        let key1 = CryptoService.randomKey()
        let key2 = CryptoService.randomKey()
        
        let data1 = key1.withUnsafeBytes { Data($0) }
        let data2 = key2.withUnsafeBytes { Data($0) }
        
        XCTAssertNotEqual(data1, data2)
        XCTAssertEqual(data1.count, 32) // 256 bits
        XCTAssertEqual(data2.count, 32)
    }
    
    func testEncryptionWithInvalidData() {
        let key = CryptoService.randomKey()
        let invalidData = Data()
        
        XCTAssertNoThrow(try CryptoService.encrypt(invalidData, using: key))
    }
    
    func testDecryptionWithWrongKey() throws {
        let plaintext = "SECRET MESSAGE".data(using: .utf8)!
        let key1 = CryptoService.randomKey()
        let key2 = CryptoService.randomKey()
        
        let encrypted = try CryptoService.encrypt(plaintext, using: key1)
        
        XCTAssertThrowsError(try CryptoService.decrypt(encrypted, using: key2))
    }
}
