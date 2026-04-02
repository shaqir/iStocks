//
//  AuthViewModelTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed
//

import XCTest
@testable import iStocks

// MARK: - Mock

final class MockBiometricAuthManager: BiometricAuthManagerProtocol {
    var authenticateResult: Result<Bool, Error> = .success(true)
    var biometryTypeValue: BiometryType = .faceID
    var isAvailable = true

    func authenticate(reason: String) async throws -> Bool {
        try authenticateResult.get()
    }

    func getBiometryType() -> BiometryType {
        biometryTypeValue
    }

    func isBiometricsAvailable() -> Bool {
        isAvailable
    }
}

// MARK: - Tests

@MainActor
final class AuthViewModelTests: XCTestCase {

    func test_authenticate_success() async {
        let mockAuth = MockBiometricAuthManager()
        mockAuth.authenticateResult = .success(true)
        let repo = AuthRepository(biometricManager: mockAuth)
        let useCase = AuthenticateUserUseCase(authRepository: repo)
        let sut = AuthViewModel(authenticateUseCase: useCase)

        sut.authenticate()

        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertFalse(sut.isAuthenticating)
        XCTAssertNil(sut.error)
    }

    func test_authenticate_failure() async {
        let mockAuth = MockBiometricAuthManager()
        mockAuth.authenticateResult = .failure(AuthError.biometryNotAvailable)
        let repo = AuthRepository(biometricManager: mockAuth)
        let useCase = AuthenticateUserUseCase(authRepository: repo)
        let sut = AuthViewModel(authenticateUseCase: useCase)

        sut.authenticate()

        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNotNil(sut.error)
    }

    func test_authenticate_userCancelled_noErrorMessage() async {
        let mockAuth = MockBiometricAuthManager()
        mockAuth.authenticateResult = .failure(AuthError.userCancelled)
        let repo = AuthRepository(biometricManager: mockAuth)
        let useCase = AuthenticateUserUseCase(authRepository: repo)
        let sut = AuthViewModel(authenticateUseCase: useCase)

        sut.authenticate()

        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertFalse(sut.isAuthenticated)
        // userCancelled has nil errorDescription — should not show error
        XCTAssertNil(sut.error)
    }
}
