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
    case mock       // development and testing
    case restAPI    // standard client
    case websocket  // real-time streaming
    case graphQL    // experiment
}

// MARK: - DI Container
/// Dependency injection container for Watchlist module
final class WatchlistDIContainer {
    
    static var mode: WatchlistAppMode {
        AppConfiguration.watchlistMode
    }
    
    private static var cachedUseCases: WatchlistUseCases?
    private static var cachedMode: WatchlistAppMode?

    // MARK: - Cached repositories
    private static var cachedMockRepository: MockWatchlistRepository?
    private static var cachedRestRepository: RestStockRepository?
    private static var cachedWebSocketRepository: StockLiveRepository?
    private static var cachedGraphQLRepository: RestStockRepository?
    
    // MARK: - Repository Factories
    
    private static func makeMockRepository() -> MockWatchlistRepository {
            if let cached = cachedMockRepository {
                return cached
            }
            let mockRepo = MockStockRepositoryImpl()
            cachedMockRepository = mockRepo
            return mockRepo
        }
    private static func makeRestRepository(context: ModelContext) -> RestStockRepository {
        if let cached = cachedRestRepository {
            return cached
        }
        let client = URLSessionNetworkClient()
        let apiService = StockRemoteDataSource(networkClient: client)
        let persistence = WatchlistPersistenceService(context: context)
        let restRepo = RestStockRepositoryImpl(service: apiService, persistenceService: persistence)
        cachedRestRepository = restRepo
        return restRepo
    }
    private static func makeWebSocketRepository() -> StockLiveRepository {
           if let cached = cachedWebSocketRepository {
               return cached
           }
           let webSocketClient = FinnhubWebSocketClient()
           let webSocketRepo = WebSocketStockRepositoryImpl(webSocket: webSocketClient)
           cachedWebSocketRepository = webSocketRepo
           return webSocketRepo
       }
    private static func makeGraphQLRepository(context: ModelContext) -> RestStockRepository {
        if let cached = cachedGraphQLRepository {
            return cached
        }
        guard let baseURL = URL(string: API.graphQLBaseURL) else {
            fatalError("Invalid GraphQL base URL configured in NetworkConstants")
        }
        let graphQLClient = GraphQLClient(baseURL: baseURL)
        let dataSource = StockGraphQLDataSource(graphQLClient: graphQLClient)
        let persistence = WatchlistPersistenceService(context: context)
        let graphQLRepo = GraphQLStockRepositoryImpl(dataSource: dataSource, persistenceService: persistence)
        cachedGraphQLRepository = graphQLRepo
        return graphQLRepo
    }

    private static func makePersistenceService(context: ModelContext) -> WatchlistPersistenceService {
        WatchlistPersistenceService(context: context)
    }

    // MARK: - Use Case Assembly
    static func makeWatchlistUseCases(context: ModelContext) -> WatchlistUseCases {
        // Invalidate caches if mode changed since last creation
        if let existing = cachedUseCases, cachedMode == mode {
            return existing
        }
        if cachedMode != mode {
            cachedUseCases = nil
            cachedMockRepository = nil
            cachedRestRepository = nil
            cachedWebSocketRepository = nil
            cachedGraphQLRepository = nil
        }
        cachedMode = mode

                let useCases: WatchlistUseCases

        switch mode {
        case .mock:
            let mockRepo = makeMockRepository()
            let persistence = makePersistenceService(context: context)
            useCases = WatchlistUseCases(
                observeMock: ObserveMockStocksUseCaseImpl(repository: mockRepo),
                observeTop50: ObserveTop50StocksUseCaseImpl(repository: mockRepo),
                observeLiveWebSocket: ObserveStockPricesUseCaseImpl(repository: mockRepo),
                fetchQuotesBySymbols: FetchStocksBySymbolUseCaseImpl(repository: mockRepo),
                saveWatchlists: SaveWatchlistsUseCaseImpl(persistenceService: persistence),
                loadWatchlists: LoadWatchlistsUseCaseImpl(persistenceService: persistence)
            )

        case .restAPI:
            let restRepo = makeRestRepository(context: context)
            let persistence = makePersistenceService(context: context)
            useCases = WatchlistUseCases(
                observeMock: ObserveMockStocksUseCaseImpl(repository: restRepo),
                observeTop50: ObserveTop50StocksUseCaseImpl(repository: restRepo),
                observeLiveWebSocket: ObserveStockPricesUseCaseImpl(repository: restRepo),
                fetchQuotesBySymbols: FetchStocksBySymbolUseCaseImpl(repository: restRepo),
                saveWatchlists: SaveWatchlistsUseCaseImpl(persistenceService: persistence),
                loadWatchlists: LoadWatchlistsUseCaseImpl(persistenceService: persistence)
            )

        case .websocket:
            let liveRepo = makeWebSocketRepository()
            let restRepo = makeRestRepository(context: context)
            let persistence = makePersistenceService(context: context)
            useCases = WatchlistUseCases(
                observeMock: ObserveMockStocksUseCaseImpl(repository: liveRepo),
                observeTop50: ObserveTop50StocksUseCaseImpl(repository: restRepo),
                observeLiveWebSocket: ObserveStockPricesUseCaseImpl(repository: liveRepo),
                fetchQuotesBySymbols: FetchStocksBySymbolUseCaseImpl(repository: restRepo),
                saveWatchlists: SaveWatchlistsUseCaseImpl(persistenceService: persistence),
                loadWatchlists: LoadWatchlistsUseCaseImpl(persistenceService: persistence)
            )

        case .graphQL:
            let graphQLRepo = makeGraphQLRepository(context: context)
            let persistence = makePersistenceService(context: context)
            useCases = WatchlistUseCases(
                observeMock: ObserveMockStocksUseCaseImpl(repository: graphQLRepo),
                observeTop50: ObserveTop50StocksUseCaseImpl(repository: graphQLRepo),
                observeLiveWebSocket: ObserveStockPricesUseCaseImpl(repository: graphQLRepo),
                fetchQuotesBySymbols: FetchStocksBySymbolUseCaseImpl(repository: graphQLRepo),
                saveWatchlists: SaveWatchlistsUseCaseImpl(persistenceService: persistence),
                loadWatchlists: LoadWatchlistsUseCaseImpl(persistenceService: persistence)
            )
        }
        
        cachedUseCases = useCases
        return useCases
    }

    // MARK: - ViewModel Factory
    @MainActor
    static func makeWatchlistsViewModel(
        mode: WatchlistAppMode,
        context: ModelContext,
        viewModelProvider: WatchlistViewModelProvider
    ) -> WatchlistsViewModel {
        let useCases = makeWatchlistUseCases(context: context)

        AppLogger.info("App started in \(mode) mode", category: AppLogger.startup)

        return WatchlistsViewModel(
            useCases: useCases,
            mode: mode,
            viewModelProvider: viewModelProvider
        )
    }
    
}

extension WatchlistDIContainer {
    /// Clears all cached instances — use on logout or mode change
    static func reset() {
        cachedUseCases = nil
        cachedMode = nil
        cachedMockRepository = nil
        cachedRestRepository = nil
        cachedWebSocketRepository = nil
        cachedGraphQLRepository = nil
    }
}
