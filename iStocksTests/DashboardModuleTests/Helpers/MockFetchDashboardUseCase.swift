//
//  MockFetchDashboardUseCase.swift
//  iStocksTests
//
//  Created by Sakir Saiyed
//

import Foundation
@testable import iStocks

final class MockFetchDashboardUseCase: FetchDashboardUseCaseProtocol, @unchecked Sendable {

    var result: Result<Dashboard, Error> = .success(.mock())
    var delay: TimeInterval = 0
    var executeCallCount = 0

    func execute(userId: String) async throws -> Dashboard {
        executeCallCount += 1
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        return try result.get()
    }
}
