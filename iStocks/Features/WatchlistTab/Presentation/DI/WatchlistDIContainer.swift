//
//  AppDIContainer.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-30.
//
import Foundation
import SwiftData

import Foundation
import SwiftData

enum WatchlistAppMode {
    case live
    case mock
}

final class WatchlistDIContainer {
    
    static let mode: WatchlistAppMode = .mock
    
    // MARK: - Repository
    static func makeStockRepository() -> StockRepository {
        switch mode {
        case .mock:
            let mockService = MockStockStreamingService()
            return MockStockRepositoryImpl(service: mockService)
        case .live:
            let client = URLSessionNetworkClient()
            let apiService = StockRemoteDataSource(networkClient: client)
            return StockRepositoryImpl(service: apiService)
        }
    }
    
    // MARK: - Use Case
    static func makeUseCase() -> ObserveStocksUseCase {
        ObserveStocksUseCaseImpl(repository: makeStockRepository())
    }

    // MARK: - Persistence Service
    static func makePersistenceService(context: ModelContext) -> WatchlistPersistenceService {
        WatchlistPersistenceService(context: context)
    }

    // MARK: - ViewModel
    static func makeWatchlistsViewModel(context: ModelContext) -> WatchlistsViewModel {
        let useCase = makeUseCase()
        let persistenceService = makePersistenceService(context: context)
        return WatchlistsViewModel(useCase: useCase, persistenceService: persistenceService)
    }
}
