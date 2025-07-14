//
//  MockStockRepositoryImpl.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-30.
//
import Foundation
import Combine

final class MockStockRepositoryImpl: WatchlistRepository {
    
    private let mockService: StockStreamingServiceProtocol

    init(service: StockStreamingServiceProtocol = MockStockStreamingService()) {
        self.mockService = service
    }

    func observeTop5Stocks() -> AnyPublisher<[Stock], Error> {
        ///NotImplementedError
         Fail(error: RepositoryError.notImplemented)
              .eraseToAnyPublisher()
    }

    func observeTop50Stocks() -> AnyPublisher<[Stock], Error> {
       ///NotImplementedError
        SharedAlertManager.shared.show(SharedAlertData(title: "Not Implemented", message: "Not Implemented", icon: "exclamationmark", action: nil))
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func observeStocks() -> AnyPublisher<[Stock], Error> {
        mockService.stockPublisher
    }
}
