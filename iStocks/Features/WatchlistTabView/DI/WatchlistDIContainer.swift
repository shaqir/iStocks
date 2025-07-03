//
//  AppDIContainer.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-30.
//
import Foundation

enum WatchlistAppMode {
    case live
    case mock
}

final class WatchlistDIContainer {
    
    // Toggle between mock and live easily
    static let mode: WatchlistAppMode = .mock

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

    static func makeUseCase() -> ObserveStocksUseCase {
        ObserveStocksUseCaseImpl(repository: makeStockRepository())
    }
    
    static func makeWatchlistsViewModel() -> WatchlistsViewModel {
        let useCase = makeUseCase()
        return WatchlistsViewModel(useCase: useCase)
    }
}
