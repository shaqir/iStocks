//
//  ObserveTop50StocksUseCase.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-10.
//
import Foundation
import Combine

/// Use case to fetch or observe the top 50 stocks from a REST API.
/// This is used to initially populate the master stock list in REST mode.
protocol ObserveTop50StocksUseCase {
    func execute() -> AnyPublisher<[Stock], Error>
}

final class ObserveTop50StocksUseCaseImpl: ObserveTop50StocksUseCase {
    let repository: RestStockRepository

    init(repository: RestStockRepository) {
        self.repository = repository
    }

    func execute() -> AnyPublisher<[Stock], Error> {
        repository.observeTop50Stocks()
    }
}
