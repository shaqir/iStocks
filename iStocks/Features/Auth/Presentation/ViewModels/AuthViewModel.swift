//
//  AuthViewModel.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Authentication state management with biometric support.
@MainActor
final class AuthViewModel: ObservableObject {

    @Published private(set) var isAuthenticated = false
    @Published private(set) var isAuthenticating = false
    @Published private(set) var error: String?
    @Published private(set) var biometryType: BiometryType = .none

    private let authenticateUseCase: AuthenticateUserUseCaseProtocol

    init(authenticateUseCase: AuthenticateUserUseCaseProtocol) {
        self.authenticateUseCase = authenticateUseCase
        self.biometryType = getBiometryType()
    }

    func authenticate() {
        Task {
            isAuthenticating = true
            error = nil

            do {
                isAuthenticated = try await authenticateUseCase.execute(
                    reason: "Authenticate to access your portfolio"
                )
            } catch let authError as AuthError {
                // NOTE: userCancelled has nil errorDescription — don't show error for intentional cancel
                self.error = authError.errorDescription
            } catch {
                self.error = error.localizedDescription
            }

            isAuthenticating = false
        }
    }

    private func getBiometryType() -> BiometryType {
        guard authenticateUseCase.isBiometricsAvailable() else { return .none }
        // Default to faceID for modern devices
        return .faceID
    }

    deinit {
        #if DEBUG
        print("[DEBUG] AuthViewModel deallocated — no retain cycle")
        #endif
    }
}
