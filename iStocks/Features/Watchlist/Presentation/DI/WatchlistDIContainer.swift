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
    
    static let mode: WatchlistAppMode = .websocket
    private static var cachedUseCases: WatchlistUseCases?
    
    // MARK: - Cached repositories
    private static var cachedMockRepository: MockWatchlistRepository?
    private static var cachedRestRepository: RestStockRepository?
    private static var cachedWebSocketRepository: StockLiveRepository?
    
    // MARK: - Repository Factories
    
    private static func makeMockRepository() -> MockWatchlistRepository {
            if let cached = cachedMockRepository {
                Logger.log("cachedMockRepository instance returned.")
                return cached
            }
            Logger.log("makeMockRepository() called.")
            let mockRepo = MockStockRepositoryImpl()
            cachedMockRepository = mockRepo
            return mockRepo
        }
    
    private static func makeRestRepository(context: ModelContext) -> RestStockRepository {
        if let cached = cachedRestRepository {
            Logger.log("cachedRestRepository instance returned.")
            return cached
        }
        Logger.log("makeRestRepository() called.")
        let client = URLSessionNetworkClient()
        let apiService = StockRemoteDataSource(networkClient: client)
        let persistence = WatchlistPersistenceService(context: context)
        let restRepo = RestStockRepositoryImpl(service: apiService, persistenceService: persistence)
        cachedRestRepository = restRepo
        return restRepo
    }
    
    private static func makeWebSocketRepository() -> StockLiveRepository {
           if let cached = cachedWebSocketRepository {
               Logger.log("cachedWebSocketRepository instance returned.")
               return cached
           }
           Logger.log("makeWebSocketRepository() called.")
           let webSocketClient = FinnhubWebSocketClient.shared
           let webSocketRepo = WebSocketStockRepositoryImpl(webSocket: webSocketClient)
           cachedWebSocketRepository = webSocketRepo
           return webSocketRepo
       }

    private static func makePersistenceService(context: ModelContext) -> WatchlistPersistenceService {
        WatchlistPersistenceService(context: context)
    }

    // MARK: - Use Case Assembly
    static func makeWatchlistUseCases(context: ModelContext) -> WatchlistUseCases {
        Logger.log("makeWatchlistUseCases() called.")
        
        if let existing = cachedUseCases {
                    Logger.log("Returning cached WatchlistUseCases instance", category: "DI")
                    return existing
                }

                let useCases: WatchlistUseCases

        switch mode {
        case .mock:
            let mockRepo = makeMockRepository()
            useCases =  WatchlistUseCases(
                observeMock: ObserveMockStocksUseCaseImpl(repository: mockRepo),
                observeTop50: ObserveTop50StocksUseCaseImpl(repository: mockRepo),
                observeLiveWebSocket: ObserveStockPricesUseCaseImpl(repository: mockRepo),
                observeWatchlist: ObserveWatchlistStocksUseCaseImpl(repository: mockRepo),
                fetchQuotesBySymbols: FetchStocksBySymbolUseCaseImpl(repository: mockRepo)
            )
            
        case .restAPI:
            let restRepo = makeRestRepository(context: context)
            useCases = WatchlistUseCases(
                observeMock: ObserveMockStocksUseCaseImpl(repository: restRepo),
                observeTop50: ObserveTop50StocksUseCaseImpl(repository: restRepo),
                observeLiveWebSocket: ObserveStockPricesUseCaseImpl(repository: restRepo),
                observeWatchlist: ObserveWatchlistStocksUseCaseImpl(repository: restRepo),
                fetchQuotesBySymbols: FetchStocksBySymbolUseCaseImpl(repository: restRepo)
            )
            
        case .websocket:
            let liveRepo = makeWebSocketRepository()
            let restRepo = makeRestRepository(context: context)
            useCases = WatchlistUseCases(
                observeMock: ObserveMockStocksUseCaseImpl(repository: liveRepo),
                observeTop50: ObserveTop50StocksUseCaseImpl(repository: restRepo),
                observeLiveWebSocket: ObserveStockPricesUseCaseImpl(repository: liveRepo),
                observeWatchlist: ObserveWatchlistStocksUseCaseImpl(repository: liveRepo),
                fetchQuotesBySymbols: FetchStocksBySymbolUseCaseImpl(repository: restRepo)
            )
        }
        
        cachedUseCases = useCases
        Logger.log("Caching WatchlistUseCases instance", category: "DI")
        return useCases
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

extension WatchlistDIContainer {
    ///Add a reset() for testing or logout
    static func resetWatchlistUseCases() {
        cachedUseCases = nil
    }
}
