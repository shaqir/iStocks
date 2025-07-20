//
//  ObserveGlobalStockPricesUseCase.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-13.
//
import Foundation
import Combine

/// Use case to observe global stock price changes for all fetched stocks.
/// Emits periodic or real-time updates to sync prices across all watchlists.
/// Mainly for .webSocket Mode
protocol ObserveStockPricesUseCase {
    func execute() -> AnyPublisher<[Stock], Never>
    func subscribe(to symbols: [String])
}

final class ObserveStockPricesUseCaseImpl: ObserveStockPricesUseCase {
    private let repository: StockLiveRepository
    
    init(repository: StockLiveRepository) {
        self.repository = repository
    }
    
    func execute() -> AnyPublisher<[Stock], Never> {
        repository.observeStocks()
            .replaceError(with: []) // or log / retry
            .eraseToAnyPublisher()
    }
    
    func subscribe(to symbols: [String]) {
        repository.subscribeToSymbols(symbols)
    }
}
