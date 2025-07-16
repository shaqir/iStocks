//
//  ObserveMockStocksUseCase.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-10.
//

import Foundation
import Combine

/// Use case to observe all mocked stock data from local source.
/// This is used in `mock` mode to simulate a full stream of stock prices.
protocol ObserveMockStocksUseCase {
    func observe() -> AnyPublisher<[Stock], Error>
}

final class ObserveMockStocksUseCaseImpl: ObserveMockStocksUseCase {
    private let repository: WatchlistRepository
    
    init(repository: WatchlistRepository) {
        self.repository = repository
    }
    
    func observe() -> AnyPublisher<[Stock], Error> {
        repository.observeStocks()
    }
}
