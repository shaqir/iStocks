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
    //case graphQL // Coming Soon
}

// MARK: - DI Container
final class WatchlistDIContainer {
    
    static let mode: WatchlistAppMode = .mock

    // MARK: - Repository Factories
    
    private static func makeMockRepository() -> MockWatchlistRepository {
        Logger.log("makeMockRepository() called.")
        return MockStockRepositoryImpl(service: MockStockStreamingService())
    }

    private static func makeRestRepository(context: ModelContext) -> RestStockRepository {
        Logger.log("makeRestRepository() called.")

        let client = URLSessionNetworkClient()
        let apiService = StockRemoteDataSource(networkClient: client)
        let persistence = WatchlistPersistenceService(context: context)
        return RestStockRepositoryImpl(service: apiService, persistenceService: persistence)
    }

    private static func makeWebSocketRepository() -> StockLiveRepository {
        Logger.log("makeWebSocketRepository() called.")
        let webSocketClient = TwelveDataWebSocketClient.shared
        return WebSocketStockRepositoryImpl(webSocket: webSocketClient)
    }

    private static func makePersistenceService(context: ModelContext) -> WatchlistPersistenceService {
        WatchlistPersistenceService(context: context)
    }

    // MARK: - Use Case Assembly
    static func makeWatchlistUseCases(context: ModelContext) -> WatchlistUseCases {
        Logger.log("makeWatchlistUseCases() called.")
        
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
            let restRepo = makeRestRepository(context: context)
            return WatchlistUseCases(
                observeMock: ObserveMockStocksUseCaseImpl(repository: restRepo),
                observeTop50: ObserveTop50StocksUseCaseImpl(repository: restRepo),
                observeLiveWebSocket: ObserveStockPricesUseCaseImpl(repository: restRepo),
                observeWatchlist: ObserveWatchlistStocksUseCaseImpl(repository: restRepo),
                fetchQuotesBySymbols: FetchStocksBySymbolUseCaseImpl(repository: restRepo)
            )
            
        case .websocket:
            let liveRepo = makeWebSocketRepository()
            let restRepo = makeRestRepository(context: context)
            return WatchlistUseCases(
                observeMock: ObserveMockStocksUseCaseImpl(repository: liveRepo),
                observeTop50: ObserveTop50StocksUseCaseImpl(repository: restRepo),
                observeLiveWebSocket: ObserveStockPricesUseCaseImpl(repository: liveRepo),
                observeWatchlist: ObserveWatchlistStocksUseCaseImpl(repository: liveRepo),
                fetchQuotesBySymbols: FetchStocksBySymbolUseCaseImpl(repository: restRepo)
            )
        }
    }

    // MARK: - ViewModel Factory
    static func makeWatchlistsViewModel(
        mode: WatchlistAppMode,
        context: ModelContext,
        viewModelProvider: WatchlistViewModelProvider
    ) -> WatchlistsViewModel {
        let useCases = makeWatchlistUseCases(context: context)
        let persistence = makePersistenceService(context: context)
        
        Logger.log("App started in \(mode) mode", category: "Startup")
        Logger.log("makeWatchlistsViewModel Factory callled.")
        
        return WatchlistsViewModel(
            useCases: useCases,
            persistenceService: persistence,
            viewModelProvider: viewModelProvider
        )
    }
}
