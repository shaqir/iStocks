//
//  ObserveGlobalStockPricesUseCaseImpl.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-13.
//
import Foundation
import Combine

/// Use case to observe global stock price changes for all fetched stocks.
/// Emits periodic or real-time updates to sync prices across all watchlists.
protocol ObserveStockPricesUseCase {
    func execute() -> AnyPublisher<[Stock], Never>
}

final class ObserveStockPricesUseCaseImpl: ObserveStockPricesUseCase {
    private let repository: WatchlistRepository

    init(repository: WatchlistRepository) {
        self.repository = repository
    }

    func execute() -> AnyPublisher<[Stock], Never> {
        repository.observeStocks()
            .replaceError(with: []) // or log / retry
            .eraseToAnyPublisher()
    }
}
