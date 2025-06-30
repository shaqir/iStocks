//
//  MockStockService.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import Combine
import Foundation

/// A mock implementation of StockServiceProtocol for testing and previews
final class MockStockService: StockServiceProtocol {

    func getWatchlistStocks() -> AnyPublisher<[Stock], Error> {
        let mockStocks = [
            Stock(symbol: "AAPL", ltp: 189.32, change: -0.63, percentChange: -0.33, invested: 100000, currentValue: 105000, groupName: "NIFTY 50"),
            Stock(symbol: "TSLA", ltp: 680.00, change: 12.50, percentChange: 1.87, invested: 50000, currentValue: 52500, groupName: "Auto"),
            Stock(symbol: "MSFT", ltp: 312.90, change: 2.10, percentChange: 0.67, invested: 70000, currentValue: 71000, groupName: "Tech")
        ]

        return Just(mockStocks)
            .setFailureType(to: Error.self)
            .delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
