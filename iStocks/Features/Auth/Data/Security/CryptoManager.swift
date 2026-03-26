//
//  CryptoManager.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import CryptoKit
import Foundation

// MARK: - Protocol

protocol CryptoManagerProtocol {
    func encrypt(_ data: Data, using key: SymmetricKey) throws -> Data
    func decrypt(_ data: Data, using key: SymmetricKey) throws -> Data
    func deriveKey(from password: String, salt: Data) -> SymmetricKey
    func generateSalt() -> Data
    func hmac(for data: Data, using key: SymmetricKey) -> Data
}

// MARK: - Errors

enum CryptoError: Error, LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case invalidData
    case integrityCheckFailed

    var errorDescription: String? {
        switch self {
        case .encryptionFailed: return "Failed to encrypt data"
        case .decryptionFailed: return "Failed to decrypt data"
        case .invalidData: return "Data is corrupted or in an unexpected format"
        case .integrityCheckFailed: return "Data integrity verification failed"
        }
    }
}

// MARK: - Implementation

/// Encryption manager using Apple's CryptoKit for sensitive financial data at rest.
///
/// NOTE: CryptoKit over CommonCrypto — modern Swift-native API with the same
/// security guarantees but safer (no raw pointers, no buffer management).
/// When asked "CommonCrypto vs CryptoKit?": CryptoKit for new code,
/// CommonCrypto only for legacy compatibility or raw C-level control.
final class CryptoManager: CryptoManagerProtocol {

    /// AES-GCM encryption (authenticated encryption — integrity built in).
    ///
    /// NOTE: GCM mode provides both confidentiality AND authenticity in one operation.
    /// The nonce and authentication tag are embedded in the sealed box's `combined` output.
    /// No separate HMAC is needed when using GCM — but we provide HMAC separately
    /// for cases where integrity needs to be verified independently of decryption.
    func encrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            guard let combined = sealedBox.combined else {
                throw CryptoError.encryptionFailed
            }
            return combined
        } catch is CryptoError {
            throw CryptoError.encryptionFailed
        } catch {
            throw CryptoError.encryptionFailed
        }
    }

    func decrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            throw CryptoError.decryptionFailed
        }
    }

    /// HKDF key derivation — converts a user password into a 256-bit encryption key.
    ///
    /// NOTE: HKDF (HMAC-based Key Derivation Function) is used here rather than
    /// PBKDF2 because CryptoKit provides it natively. For password-based key
    /// derivation in production, consider using Argon2 or bcrypt via a wrapper.
    func deriveKey(from password: String, salt: Data) -> SymmetricKey {
        let passwordData = Data(password.utf8)
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: passwordData),
            salt: salt,
            info: Data("iStocks-v1".utf8),
            outputByteCount: 32 // 256-bit key
        )
    }

    /// Generates a cryptographically secure random salt.
    ///
    /// NOTE: SecRandomCopyBytes uses the system's cryptographic random number generator.
    /// Never use `arc4random` or `Int.random` for cryptographic purposes.
    func generateSalt() -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }

    /// HMAC for data integrity verification.
    ///
    /// NOTE: Use this when you need to verify data integrity without decrypting.
    /// Example: verify a cached portfolio file hasn't been tampered with before
    /// loading it, without needing to decrypt the entire file first.
    func hmac(for data: Data, using key: SymmetricKey) -> Data {
        let mac = HMAC<SHA256>.authenticationCode(for: data, using: key)
        return Data(mac)
    }
}
