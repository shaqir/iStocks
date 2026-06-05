//
//  DashboardViewModelTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed
//

import XCTest
@testable import iStocks

@MainActor
final class DashboardViewModelTests: XCTestCase {

    var sut: DashboardViewModel!
    var mockUseCase: MockFetchDashboardUseCase!

    override func setUp() async throws {
        try await super.setUp()
        mockUseCase = MockFetchDashboardUseCase()
        sut = DashboardViewModel(fetchDashboardUseCase: mockUseCase)
    }

    override func tearDown() async throws {
        sut = nil
        mockUseCase = nil
        try await super.tearDown()
    }

    // MARK: - Success

    func test_onAppear_loadsDashboardSuccessfully() async {
        let expected = Dashboard.mock()
        mockUseCase.result = .success(expected)

        sut.onAppear()

        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertNotNil(sut.dashboard)
        XCTAssertEqual(sut.dashboard?.totalValue, expected.totalValue)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    // MARK: - Error Handling

    func test_onAppear_handlesError() async {
        mockUseCase.result = .failure(NetworkError.httpError(statusCode: 500, data: Data()))

        sut.onAppear()

        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertNil(sut.dashboard)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.error)
    }

    // MARK: - Cancellation

    func test_onDisappear_cancelsLoadTask() async {
        mockUseCase.delay = 2.0 // Simulate slow network

        sut.onAppear()
        try? await Task.sleep(nanoseconds: 50_000_000) // Let task start
        sut.onDisappear()

        try? await Task.sleep(nanoseconds: 200_000_000)

        // Dashboard should NOT be loaded because task was cancelled
        XCTAssertNil(sut.dashboard)
    }

    // MARK: - Refresh

    func test_refresh_updatesDashboard() async {
        let expected = Dashboard.mock()
        mockUseCase.result = .success(expected)

        await sut.refresh()

        XCTAssertNotNil(sut.dashboard)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
}
