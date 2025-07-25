//
//  MockRemoteDataSource.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2025-07-23.
//

import Foundation
import Combine
@testable import iStocks

final class MockRemoteDataSource: StockRemoteDataSourceProtocol {
    
    var fetchCalled = false
    var symbolsRequested: [String] = []
    
    // Mock for fetchRealtimePrices(for:)
    func fetchRealtimePrices(for symbols: [String]) -> AnyPublisher<[Stock], Error> {
        fetchCalled = true
        symbolsRequested = symbols
        
        let mockStocks = symbols.map {
            MockStock(symbol: $0, price: 123.45).toDomain()
        }
        
        return Just(mockStocks)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    // Mock for fetchRealtimePricesForTop50InBatches(...)
    func fetchRealtimePricesForTop50InBatches(
        _ symbols: [String],
        batchSize: Int,
        onProgress: BatchProgressHandler? = nil
    ) -> AnyPublisher<[Stock], Error> {
        fetchCalled = true
        symbolsRequested = symbols
        
        let mockStocks = symbols.map {
            MockStock(symbol: $0, price: 99.99).toDomain()
        }
        
        // Simulate one batch completed
        onProgress?(1, 1, 0, true)
        
        return Just(mockStocks)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
}
