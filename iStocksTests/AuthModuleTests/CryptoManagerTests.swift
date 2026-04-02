//
//  CryptoManagerTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed
//

import XCTest
import CryptoKit
@testable import iStocks

final class CryptoManagerTests: XCTestCase {

    let sut = CryptoManager()

    // MARK: - Encrypt / Decrypt Roundtrip

    func test_encryptDecrypt_roundtrip() throws {
        let key = SymmetricKey(size: .bits256)
        let originalData = Data("Sensitive portfolio data".utf8)

        let encrypted = try sut.encrypt(originalData, using: key)
        let decrypted = try sut.decrypt(encrypted, using: key)

        XCTAssertEqual(decrypted, originalData)
        XCTAssertNotEqual(encrypted, originalData) // Encrypted should differ
    }

    // MARK: - Wrong Key

    func test_decrypt_withWrongKey_throws() throws {
        let key1 = SymmetricKey(size: .bits256)
        let key2 = SymmetricKey(size: .bits256)
        let data = Data("Secret".utf8)

        let encrypted = try sut.encrypt(data, using: key1)

        XCTAssertThrowsError(try sut.decrypt(encrypted, using: key2)) { error in
            XCTAssertTrue(error is CryptoError)
        }
    }

    // MARK: - Key Derivation

    func test_deriveKey_sameInputsSameKey() {
        let salt = sut.generateSalt()
        let key1 = sut.deriveKey(from: "password123", salt: salt)
        let key2 = sut.deriveKey(from: "password123", salt: salt)

        // Same password + same salt = same key (deterministic)
        XCTAssertEqual(
            key1.withUnsafeBytes { Data($0) },
            key2.withUnsafeBytes { Data($0) }
        )
    }

    func test_deriveKey_differentSaltsDifferentKeys() {
        let salt1 = sut.generateSalt()
        let salt2 = sut.generateSalt()
        let key1 = sut.deriveKey(from: "password123", salt: salt1)
        let key2 = sut.deriveKey(from: "password123", salt: salt2)

        XCTAssertNotEqual(
            key1.withUnsafeBytes { Data($0) },
            key2.withUnsafeBytes { Data($0) }
        )
    }

    // MARK: - HMAC

    func test_hmac_validatesIntegrity() {
        let key = SymmetricKey(size: .bits256)
        let data = Data("Portfolio balance: $50,000".utf8)

        let mac1 = sut.hmac(for: data, using: key)
        let mac2 = sut.hmac(for: data, using: key)

        // Same data + same key = same HMAC (deterministic)
        XCTAssertEqual(mac1, mac2)
    }

    func test_hmac_detectsTampering() {
        let key = SymmetricKey(size: .bits256)
        let original = Data("Balance: $50,000".utf8)
        let tampered = Data("Balance: $500,000".utf8)

        let originalMAC = sut.hmac(for: original, using: key)
        let tamperedMAC = sut.hmac(for: tampered, using: key)

        XCTAssertNotEqual(originalMAC, tamperedMAC)
    }

    // MARK: - Salt Generation

    func test_generateSalt_producesUniqueValues() {
        let salt1 = sut.generateSalt()
        let salt2 = sut.generateSalt()

        XCTAssertNotEqual(salt1, salt2)
        XCTAssertEqual(salt1.count, 32)
    }
}
