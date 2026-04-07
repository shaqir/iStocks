//
//  AuthRepositoryProtocol.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Repository protocol for authentication operations.
///
/// NOTE: Domain layer protocol — zero UIKit/SwiftUI/LocalAuthentication imports.
/// The Data layer implementation (AuthRepository) wraps BiometricAuthManager
/// which imports LocalAuthentication. This separation means the domain logic
/// can be tested without a real biometric sensor.
nonisolated protocol AuthRepositoryProtocol {

    /// Attempts biometric authentication with the given reason string.
    /// - Returns: `true` if authentication succeeded.
    /// - Throws: AuthError with specific failure reason.
    func authenticate(reason: String) async throws -> Bool

    /// Whether biometric authentication is available on this device.
    func isBiometricsAvailable() -> Bool
}
