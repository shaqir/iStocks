//
//  BiometricAuthManager.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import LocalAuthentication

// MARK: - Protocol

/// NOTE: Protocol-based design enables MockBiometricAuthManager in tests —
/// no real biometric sensor needed for unit testing auth flows.
nonisolated protocol BiometricAuthManagerProtocol: Sendable {
    func authenticate(reason: String) async throws -> Bool
    func getBiometryType() -> BiometryType
    func isBiometricsAvailable() -> Bool
}

// MARK: - Types

nonisolated enum BiometryType: Sendable {
    case faceID, touchID, opticID, none
}

/// NOTE: Every LAError case is mapped explicitly — no catch-all that swallows errors.
/// In a financial app, silent auth failures are unacceptable. Each case gets a
/// user-facing message and a recovery path.
nonisolated enum AuthError: Error, LocalizedError, Sendable {
    case biometryNotAvailable
    case biometryNotEnrolled
    case biometryLockout
    case userCancelled
    case fallbackRequested
    case systemCancel
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .biometryNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometryNotEnrolled:
            return "No biometric data enrolled. Please set up Face ID or Touch ID in Settings."
        case .biometryLockout:
            return "Biometric authentication is locked. Please use your device passcode."
        case .userCancelled:
            return nil // User chose to cancel — no error message needed
        case .fallbackRequested:
            return "Please enter your PIN"
        case .systemCancel:
            return "Authentication was interrupted"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Implementation

/// Wraps LocalAuthentication framework with full error handling and fallback chain.
///
/// NOTE: Key security insight — biometric data NEVER leaves the Secure Enclave.
/// The app only receives a boolean result. Apple's hardware handles the actual
/// biometric matching in an isolated processor. We cannot (and should not)
/// access raw biometric data.
nonisolated final class BiometricAuthManager: BiometricAuthManagerProtocol {

    func getBiometryType() -> BiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        case .none: return .none
        @unknown default: return .none
        }
    }

    func isBiometricsAvailable() -> Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Use PIN Instead"
        context.localizedCancelTitle = "Cancel"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw mapLAError(error)
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch let laError as LAError {
            throw mapLAError(laError)
        }
    }

    // MARK: - Error Mapping

    /// NOTE: Handle every LAError case — no silent failures in auth.
    /// Each case maps to a domain-specific AuthError with a user-facing message.
    private func mapLAError(_ error: NSError?) -> AuthError {
        guard let error = error else { return .biometryNotAvailable }

        switch LAError.Code(rawValue: error.code) {
        case .biometryNotAvailable: return .biometryNotAvailable
        case .biometryNotEnrolled: return .biometryNotEnrolled
        case .biometryLockout: return .biometryLockout
        case .userCancel: return .userCancelled
        case .userFallback: return .fallbackRequested
        case .systemCancel: return .systemCancel
        default: return .unknown(error.localizedDescription)
        }
    }

    private func mapLAError(_ error: LAError) -> AuthError {
        switch error.code {
        case .biometryNotAvailable: return .biometryNotAvailable
        case .biometryNotEnrolled: return .biometryNotEnrolled
        case .biometryLockout: return .biometryLockout
        case .userCancel: return .userCancelled
        case .userFallback: return .fallbackRequested
        case .systemCancel: return .systemCancel
        case .authenticationFailed,
             .appCancel,
             .invalidContext,
             .notInteractive,
             .passcodeNotSet,
             .touchIDNotAvailable,
             .touchIDNotEnrolled,
             .touchIDLockout,
             .companionNotAvailable:
            return .unknown(error.localizedDescription)
        @unknown default: return .unknown(error.localizedDescription)
        }
    }
}
