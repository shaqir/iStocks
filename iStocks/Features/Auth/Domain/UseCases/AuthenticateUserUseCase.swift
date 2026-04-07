//
//  AuthenticateUserUseCase.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Use case protocol for authentication — domain layer, zero framework imports.
nonisolated protocol AuthenticateUserUseCaseProtocol: Sendable {
    func execute(reason: String) async throws -> Bool
    func isBiometricsAvailable() -> Bool
}

/// Wraps the auth repository in a use case for clean architecture compliance.
///
/// NOTE: This seems like a thin wrapper, and it is — but it serves a purpose.
/// The ViewModel depends on the UseCase protocol, not the Repository directly.
/// If authentication logic grows (e.g., combining biometrics + PIN + server
/// token refresh), the complexity lives here — not in the ViewModel.
/// NOTE (Swift 6.2): @unchecked Sendable — immutable after init, safe to cross actor boundaries.
nonisolated final class AuthenticateUserUseCase: AuthenticateUserUseCaseProtocol, @unchecked Sendable {

    private let authRepository: AuthRepositoryProtocol

    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    func execute(reason: String) async throws -> Bool {
        try await authRepository.authenticate(reason: reason)
    }

    func isBiometricsAvailable() -> Bool {
        authRepository.isBiometricsAvailable()
    }
}
