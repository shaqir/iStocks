//
//  ObserveStockUseCaseImpl.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-30.
//
import Foundation
import Combine

protocol ObserveTop5StocksUseCase {
    func execute() -> AnyPublisher<[Stock], any Error>
}

final class ObserveTop5StocksUseCaseImpl: ObserveTop5StocksUseCase{
    private let repository: StockRepository
    
    init(repository: StockRepository) {
        self.repository = repository
    }
    
    func execute() -> AnyPublisher<[Stock], Error> {
        repository.observeTop5Stocks()
    }
}
