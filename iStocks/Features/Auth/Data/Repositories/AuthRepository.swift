//
//  AuthRepository.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Concrete auth repository that delegates to BiometricAuthManager.
///
/// NOTE: The repository pattern here provides the seam for testing.
/// Tests inject MockBiometricAuthManager via the protocol — no real
/// biometric sensor needed for unit tests.
nonisolated final class AuthRepository: AuthRepositoryProtocol {

    private let biometricManager: BiometricAuthManagerProtocol

    init(biometricManager: BiometricAuthManagerProtocol) {
        self.biometricManager = biometricManager
    }

    func authenticate(reason: String) async throws -> Bool {
        try await biometricManager.authenticate(reason: reason)
    }

    func isBiometricsAvailable() -> Bool {
        biometricManager.isBiometricsAvailable()
    }
}
