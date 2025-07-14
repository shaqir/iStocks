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
    
    // MARK: - Use Cases
    static func makeMockUseCase() -> ObserveMockStocksUseCase {
        ObserveMockStocksUseCaseImpl(repository: makeStockRepository())
    }
    
    static func makeTop5UseCase() -> ObserveTop5StocksUseCase {
        ObserveTop5StocksUseCaseImpl(repository: makeStockRepository())
    }

    static func makeTop50UseCase() -> ObserveTop50StocksUseCase {
        ObserveTop50StocksUseCaseImpl(repository: makeStockRepository())
    }
    
    static func makeWatchlistStocksUseCase() -> ObserveWatchlistStocksUseCase {
        ObserveWatchlistStocksUseCaseImpl(repository: makeStockRepository())
    }
    
    static func makeGlobalPriceUpdateUseCase() -> ObserveGlobalStockPricesUseCase {
        ObserveGlobalStockPricesUseCaseImpl(repository: makeStockRepository())
    }

    // MARK: - Persistence Service
    static func makePersistenceService(context: ModelContext) -> WatchlistPersistenceService {
        WatchlistPersistenceService(context: context)
    }

    // MARK: - ViewModel
    static func makeWatchlistsViewModel(context: ModelContext) -> WatchlistsViewModel {
        let useCaseMock = makeMockUseCase()
        let useCase50 = makeTop50UseCase()
        let useCaseWatchlist = makeWatchlistStocksUseCase()
        let useCasePriceUpdate = makeGlobalPriceUpdateUseCase()
        let persistenceService = makePersistenceService(context: context)
        let vmProvider = WatchlistViewModelProvider(observeUseCase: useCaseWatchlist)
        
        return WatchlistsViewModel(
            useCaseMock: useCaseMock,
            useCase50: useCase50,
            watchlistUseCase: useCaseWatchlist,
            globalPricesUseCase: useCasePriceUpdate,
            persistenceService: persistenceService,
            viewModelProvider: vmProvider
        )
    }
    
    static func makeWatchlistsViewModel(
        context: ModelContext,
        viewModelProvider: WatchlistViewModelProvider
    ) -> WatchlistsViewModel {
        let useCaseMock = makeMockUseCase()
        let useCase50 = makeTop50UseCase()
        let useCaseWatchlist = makeWatchlistStocksUseCase()
        let useCasePriceUpdate = makeGlobalPriceUpdateUseCase()
        let persistenceService = makePersistenceService(context: context)

        return WatchlistsViewModel(
            useCaseMock: useCaseMock,
            useCase50: useCase50,
            watchlistUseCase: useCaseWatchlist,
            globalPricesUseCase: useCasePriceUpdate,
            persistenceService: persistenceService,
            viewModelProvider: viewModelProvider
        )
    }
    
}
 
