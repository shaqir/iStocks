//
//  ObserveTop50StocksUseCaseImpl.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-10.
//

import Foundation
import Combine

protocol ObserveTop50StocksUseCase {
    func execute() -> AnyPublisher<[Stock], Never>
}

final class ObserveTop50StocksUseCaseImpl: ObserveTop50StocksUseCase {
    private let repository: StockRepository

    init(repository: StockRepository) {
        self.repository = repository
    }

    func execute() -> AnyPublisher<[Stock], Never> {
        repository.observeTop50Stocks()
    }
}
