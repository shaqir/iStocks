//
//  AppDIContainer.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-30.
//
import Foundation
import SwiftData

// MARK: - App Mode Enum
enum WatchlistAppMode {
    case mock
    case restAPI
    case websocket
}

// MARK: - DI Container
final class WatchlistDIContainer {
    static let mode: WatchlistAppMode = .websocket
    
    // MARK: - Repository Factories
    
    private static func makeMockRepository() -> MockWatchlistRepository {
        MockStockRepositoryImpl(service: MockStockStreamingService())
    }

    private static func makeRestRepository() -> RestStockRepository {
        let client = URLSessionNetworkClient()
        let apiService = StockRemoteDataSource(networkClient: client)
        return RestStockRepositoryImpl(service: apiService)
    }

    private static func makeWebSocketRepository() -> StockLiveRepository {
        let webSocketClient = TwelveDataWebSocketClient()
        return WebSocketStockRepositoryImpl(webSocket: webSocketClient)
    }

    // MARK: - Use Case Assembly
    static func makeWatchlistUseCases() -> WatchlistUseCases {
        switch mode {
        case .mock:
            let mockRepo = makeMockRepository()
            return WatchlistUseCases(
                observeMock: ObserveMockStocksUseCaseImpl(repository: mockRepo),
                observeTop50: ObserveTop50StocksUseCaseImpl(repository: mockRepo),
                observeLiveWebSocket: ObserveStockPricesUseCaseImpl(repository: mockRepo),
                observeWatchlist: ObserveWatchlistStocksUseCaseImpl(repository: mockRepo),
                fetchQuotesBySymbols: FetchStocksBySymbolUseCaseImpl(repository: mockRepo)
            )

        case .restAPI:
            let restRepo = makeRestRepository()
            return WatchlistUseCases(
                observeMock: ObserveMockStocksUseCaseImpl(repository: restRepo), // fallback
                observeTop50: ObserveTop50StocksUseCaseImpl(repository: restRepo),
                observeLiveWebSocket: ObserveStockPricesUseCaseImpl(repository: restRepo), // fallback
                observeWatchlist: ObserveWatchlistStocksUseCaseImpl(repository: restRepo),
                fetchQuotesBySymbols: FetchStocksBySymbolUseCaseImpl(repository: restRepo)
            )

        case .websocket:
            let liveRepo = makeWebSocketRepository()
            let restRepo = makeRestRepository()
            return WatchlistUseCases(
                observeMock: ObserveMockStocksUseCaseImpl(repository: liveRepo),
                observeTop50: ObserveTop50StocksUseCaseImpl(repository: restRepo), // separated
                observeLiveWebSocket: ObserveStockPricesUseCaseImpl(repository: liveRepo),
                observeWatchlist: ObserveWatchlistStocksUseCaseImpl(repository: liveRepo),
                fetchQuotesBySymbols: FetchStocksBySymbolUseCaseImpl(repository: restRepo)
            )
        }
    }

    // MARK: - Persistence
    static func makePersistenceService(context: ModelContext) -> WatchlistPersistenceService {
        WatchlistPersistenceService(context: context)
    }

    // MARK: - ViewModel Factory
    static func makeWatchlistsViewModel(
        context: ModelContext,
        viewModelProvider: WatchlistViewModelProvider
    ) -> WatchlistsViewModel {
        let useCases = makeWatchlistUseCases()
        let persistence = makePersistenceService(context: context)
        
        Logger.log("App started in \(mode) mode", category: "Startup")
        
        return WatchlistsViewModel(
            useCases: useCases,
            persistenceService: persistence,
            viewModelProvider: viewModelProvider
        )
    }
}
