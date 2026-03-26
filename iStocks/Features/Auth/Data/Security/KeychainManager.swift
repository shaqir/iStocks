//
//  KeychainManager.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Security
import LocalAuthentication

// MARK: - Protocol

protocol KeychainManagerProtocol {
    func save(_ data: Data, for key: String, requireBiometric: Bool) throws
    func load(for key: String) throws -> Data
    func delete(for key: String) throws
}

// MARK: - Errors

enum KeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Keychain save failed with status: \(status)"
        case .loadFailed(let status):
            return "Keychain load failed with status: \(status)"
        case .deleteFailed(let status):
            return "Keychain delete failed with status: \(status)"
        }
    }
}

// MARK: - Implementation

/// Secure credential storage using the iOS Keychain.
///
/// NOTE: Keychain data survives app deletion and reinstallation (unless
/// kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly is used, which ties
/// data to the current device passcode). Choose accessibility carefully
/// based on the sensitivity of the data.
final class KeychainManager: KeychainManagerProtocol {

    func save(_ data: Data, for key: String, requireBiometric: Bool = false) throws {
        // Delete existing item first to avoid errSecDuplicateItem
        try? delete(for: key)

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // NOTE: Biometric-protected entries use SecAccessControl with .biometryCurrentSet.
        // .biometryCurrentSet means the keychain item is INVALIDATED if the user
        // adds or removes a fingerprint/face. This prevents a compromised biometric
        // (e.g., someone enrolls their face while device is unlocked) from accessing
        // previously stored credentials.
        if requireBiometric {
            let accessControl = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                .biometryCurrentSet,
                nil
            )
            query[kSecAttrAccessControl as String] = accessControl
        }

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    func load(for key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.loadFailed(status)
        }

        return data
    }

    func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        // NOTE: errSecItemNotFound is acceptable — deleting a non-existent item is a no-op.
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}
