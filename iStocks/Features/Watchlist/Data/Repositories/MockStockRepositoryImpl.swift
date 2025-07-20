//
//  MockStockRepositoryImpl.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-30.
//
import Foundation
import Combine

final class MockStockRepositoryImpl: MockWatchlistRepository {
    
    private let mockService: StockStreamingServiceProtocol
    
    init(service: StockStreamingServiceProtocol = MockStockStreamingService()) {
        self.mockService = service
    }
    
    func observeStocks() -> AnyPublisher<[Stock], Error> {
        mockService.start()///// Start price simulation only when observed
        return mockService.stockPublisher
    }
    ///stop updates when a user logs out or test ends:
    func stopUpdates() {
        mockService.stop()
    }
    
}
