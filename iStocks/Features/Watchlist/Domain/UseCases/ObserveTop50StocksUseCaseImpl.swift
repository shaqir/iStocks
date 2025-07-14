//
//  ObserveTop50StocksUseCaseImpl.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-10.
//

import Foundation
import Combine

protocol ObserveTop50StocksUseCase {
    func execute() -> AnyPublisher<[Stock], Error>
}

final class ObserveTop50StocksUseCaseImpl: ObserveTop50StocksUseCase {
    private let repository: WatchlistRepository

    init(repository: WatchlistRepository) {
        self.repository = repository
    }

    func execute() -> AnyPublisher<[Stock], Error> {
        repository.observeTop50Stocks()
    }
}
