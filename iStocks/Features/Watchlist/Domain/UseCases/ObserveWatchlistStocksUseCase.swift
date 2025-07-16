//
//  ObserveWatchlistStocksUseCaseImpl.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-11.
//

import Foundation
import Combine

/// Use case to observe live price updates only for stocks within a specific watchlist.
/// Filters global updates to only those relevant to the given watchlist.
protocol ObserveWatchlistStocksUseCase {
    func observeLiveUpdates(for watchlist: Watchlist) -> AnyPublisher<[Stock], Never>
}
 
final class ObserveWatchlistStocksUseCaseImpl: ObserveWatchlistStocksUseCase {
    private let repository: WatchlistRepository

    init(repository: WatchlistRepository) {
        self.repository = repository
    }

    func observeLiveUpdates(for watchlist: Watchlist) -> AnyPublisher<[Stock], Never> {
        repository
            .observeStocks()
            .map { allStocks in
                allStocks.filter { stock in
                    watchlist.stocks.contains(where: { $0.symbol == stock.symbol })
                }
            }
            .replaceError(with: watchlist.stocks) // fallback to last known if error occurs
            .eraseToAnyPublisher()
    }
}
