//
//  AuthDIContainer.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Dependency injection container for the Auth feature module.
final class AuthDIContainer {

    static func makeBiometricAuthManager() -> BiometricAuthManagerProtocol {
        BiometricAuthManager()
    }

    static func makeAuthRepository() -> AuthRepositoryProtocol {
        AuthRepository(biometricManager: makeBiometricAuthManager())
    }

    static func makeAuthenticateUserUseCase() -> AuthenticateUserUseCaseProtocol {
        AuthenticateUserUseCase(authRepository: makeAuthRepository())
    }

    @MainActor
    static func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(authenticateUseCase: makeAuthenticateUserUseCase())
    }
}
