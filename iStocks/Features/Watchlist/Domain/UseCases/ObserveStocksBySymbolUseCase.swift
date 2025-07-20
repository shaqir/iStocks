//
//  ObserveStocksBySymbolUseCase.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-18.
//

import Foundation
import Combine

/// This is for Particular Symbols to fetch from REST API
protocol FetchStocksBySymbolUseCase {
    func execute(for symbols: [String]) -> AnyPublisher<[Stock], Error>
}

final class FetchStocksBySymbolUseCaseImpl: FetchStocksBySymbolUseCase {
    
    private let repository: RestStockRepository
    
    init(repository: RestStockRepository) {
        self.repository = repository
    }
    
    func execute(for symbols: [String]) -> AnyPublisher<[Stock], Error> {
            repository.fetchStockQuotes(for: symbols)
    }
}
