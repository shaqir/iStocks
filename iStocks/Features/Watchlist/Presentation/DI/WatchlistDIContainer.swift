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
    case webSocket
}

struct WatchlistUseCases {
    let observeMock: ObserveMockStocksUseCase
    let observeTop50: ObserveTop50StocksUseCase
    let observeWatchlist: ObserveWatchlistStocksUseCase
    let observeGlobalPrices: ObserveGlobalStockPricesUseCase
    // Future UseCases can be added here (delete, rename, import, etc.)
}

final class WatchlistDIContainer {
    
    static let mode: WatchlistAppMode = .mock
    
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
        case .webSocket:
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
            observeGlobalPrices: ObserveGlobalStockPricesUseCaseImpl(repository: repository)
        )
    }

    static func makeWatchlistsViewModel(context: ModelContext) -> WatchlistsViewModel {
        let useCases = makeWatchlistUseCases()
        let persistenceService = makePersistenceService(context: context)
        let viewModelProvider = WatchlistViewModelProvider(useCases: useCases)
        return WatchlistsViewModel(
            useCases: useCases,
            persistenceService: persistenceService,
            viewModelProvider: viewModelProvider
        )
    }

    static func makeWatchlistsViewModel(
        context: ModelContext,
        viewModelProvider: WatchlistViewModelProvider
    ) -> WatchlistsViewModel {
        let useCases = makeWatchlistUseCases()
        let persistenceService = makePersistenceService(context: context)

        return WatchlistsViewModel(
            useCases: useCases,
            persistenceService: persistenceService,
            viewModelProvider: viewModelProvider
        )
    }
}
