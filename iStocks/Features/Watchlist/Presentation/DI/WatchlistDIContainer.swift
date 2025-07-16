//
//  AppDIContainer.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-30.
//
import Foundation
import SwiftData

enum WatchlistAppMode {
    case mock
    case restAPI
}

final class WatchlistDIContainer {
    
    static let mode: WatchlistAppMode = .restAPI
    
    // MARK: - Repository
    static func makeStockRepository() -> WatchlistRepository {
        switch mode {
        case .mock:
            let mockService = MockStockStreamingService()
            return MockStockRepositoryImpl(service: mockService)
        case .restAPI:
            let client = URLSessionNetworkClient()
            let apiService = StockRemoteDataSource(networkClient: client)
            return StockRepositoryImpl(service: apiService)
        }
    }
    
    // MARK: - Persistence Service
    static func makePersistenceService(context: ModelContext) -> WatchlistPersistenceService {
        WatchlistPersistenceService(context: context)
    }
    
}

extension WatchlistDIContainer {
    
    static func makeWatchlistUseCases() -> WatchlistUseCases {
        let repository = makeStockRepository()
        return WatchlistUseCases(
            observeMock: ObserveMockStocksUseCaseImpl(repository: repository),
            observeTop50: ObserveTop50StocksUseCaseImpl(repository: repository),
            observeWatchlist: ObserveWatchlistStocksUseCaseImpl(repository: repository),
            observeGlobalPrices: ObserveStockPricesUseCaseImpl(repository: repository)
        )
    }
    
    static func makeWatchlistsViewModel(
        context: ModelContext,
        viewModelProvider: WatchlistViewModelProvider
    ) -> WatchlistsViewModel {
        let useCases = makeWatchlistUseCases()
        let persistenceService = makePersistenceService(context: context)
        
        Logger.log("App started in \(mode) mode", category: "Startup")
        
        return WatchlistsViewModel(
            useCases: useCases,
            persistenceService: persistenceService,
            viewModelProvider: viewModelProvider
        )
    }
}
