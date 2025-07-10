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
    
    static let mode: WatchlistAppMode = .restAPI
    
    // MARK: - Repository
    static func makeStockRepository() -> StockRepository {
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
        let vmProvider = WatchlistViewModelProvider()
        return WatchlistsViewModel(useCase: useCase,
                                   persistenceService: persistenceService,
                                   viewModelProvider: vmProvider)
    }
}
