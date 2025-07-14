//
//  ObserveGlobalStockPricesUseCaseImpl.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-13.
//
import Foundation
import Combine

protocol ObserveGlobalStockPricesUseCase {
    func execute() -> AnyPublisher<[Stock], Never>
}

final class ObserveGlobalStockPricesUseCaseImpl: ObserveGlobalStockPricesUseCase {
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
