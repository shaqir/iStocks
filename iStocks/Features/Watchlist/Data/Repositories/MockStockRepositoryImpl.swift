//
//  MockStockRepositoryImpl.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-30.
//
import Foundation
import Combine

final class MockStockRepositoryImpl: StockRepository {
    
    private let mockService: StockStreamingServiceProtocol
    
    init(service: StockStreamingServiceProtocol = MockStockStreamingService()) {
        self.mockService = service
    }
    
    func observeStocks() -> AnyPublisher<[Stock], any Error> {
        mockService.stockPublisher // Mocked Interval data
    }
     
}
