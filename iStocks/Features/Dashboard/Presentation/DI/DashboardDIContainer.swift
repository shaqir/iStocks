//
//  DashboardDIContainer.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Dependency injection container for the Dashboard feature module.
///
/// NOTE: Follows the same static factory pattern as WatchlistDIContainer —
/// cached singletons where appropriate, protocol-based for testability.
final class DashboardDIContainer {

    // MARK: - Cached Instances

    private static var cachedPortfolioActor: PortfolioActor?
    private static var cachedRepository: StockRepositoryProtocol?

    // MARK: - Factories

    static func makeAPIClient() -> APIClientProtocol {
        URLSessionAPIClient()
    }

    static func makeStockRepository() -> StockRepositoryProtocol {
        if let cached = cachedRepository { return cached }
        let repo = StockRepository(apiClient: makeAPIClient())
        cachedRepository = repo
        return repo
    }

    static func makePortfolioActor() -> PortfolioActor {
        if let cached = cachedPortfolioActor { return cached }
        let actor = PortfolioActor()
        cachedPortfolioActor = actor
        return actor
    }

    static func makeFetchDashboardUseCase() -> FetchDashboardUseCaseProtocol {
        FetchDashboardUseCase(
            stockRepository: makeStockRepository(),
            portfolio: makePortfolioActor()
        )
    }

    @MainActor
    static func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(fetchDashboardUseCase: makeFetchDashboardUseCase())
    }

    // MARK: - Reset (for testing)

    static func reset() {
        cachedPortfolioActor = nil
        cachedRepository = nil
    }
}
