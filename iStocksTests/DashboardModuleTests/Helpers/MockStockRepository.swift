//
//  MockStockRepository.swift
//  iStocksTests
//
//  Created by Sakir Saiyed
//

import Foundation
@testable import iStocks

final class MockStockRepository: StockRepositoryProtocol, @unchecked Sendable {

    var holdingsResult: Result<[Holding], Error> = .success([.mock()])
    var priceResult: Result<Double, Error> = .success(155.0)
    var newsResult: Result<[News], Error> = .success([.mock()])
    var priceDelay: TimeInterval = 0

    func fetchHoldings(userId: String) async throws -> [Holding] {
        try holdingsResult.get()
    }

    func fetchPrice(for symbol: String) async throws -> Double {
        if priceDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(priceDelay * 1_000_000_000))
        }
        return try priceResult.get()
    }

    func fetchNews(for symbols: [String]) async throws -> [News] {
        try newsResult.get()
    }
}
