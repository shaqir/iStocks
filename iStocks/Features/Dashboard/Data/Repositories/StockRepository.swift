//
//  StockRepository.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Concrete repository implementation using the generic APIClient.
///
/// NOTE: This class demonstrates how the APIEndpoint protocol's associated types
/// provide compile-time type safety. Each endpoint struct declares its own
/// Response type — the client automatically decodes to the correct type.
final class StockRepository: StockRepositoryProtocol, @unchecked Sendable {

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func fetchHoldings(userId: String) async throws -> [Holding] {
        // NOTE: In production, this would call a real holdings endpoint.
        // For demo, return mock data to demonstrate the architecture.
        return [
            .mock(symbol: "AAPL", name: "Apple Inc.", currentPrice: 150.0),
            .mock(symbol: "GOOGL", name: "Alphabet Inc.", currentPrice: 2800.0),
            .mock(symbol: "MSFT", name: "Microsoft Corp.", currentPrice: 380.0),
            .mock(symbol: "TSLA", name: "Tesla Inc.", currentPrice: 250.0),
            .mock(symbol: "AMZN", name: "Amazon.com Inc.", currentPrice: 185.0)
        ]
    }

    func fetchPrice(for symbol: String) async throws -> Double {
        // NOTE: In production this calls the TwelveData /price endpoint via APIClient.
        // Mock prices here so the Dashboard demo works without an API key configured.
        #if DEBUG
        let mockPrices: [String: Double] = [
            "AAPL": 153.25, "GOOGL": 2834.50, "MSFT": 384.20,
            "TSLA": 247.60, "AMZN": 188.90
        ]
        try await Task.sleep(nanoseconds: 200_000_000) // simulate network latency
        return mockPrices[symbol] ?? 100.0
        #else
        let endpoint = PriceQuoteEndpoint(symbol: symbol)
        let response = try await apiClient.request(endpoint)
        return response.price
        #endif
    }

    func fetchNews(for symbols: [String]) async throws -> [News] {
        // NOTE: In production, this would call a news API.
        // For demo, return mock data.
        return [
            .mock(headline: "\(symbols.first ?? "Stock") hits new high"),
            .mock(headline: "Market update: Tech sector rallies", source: "Bloomberg")
        ]
    }
}

// MARK: - Concrete Endpoint Definitions

/// NOTE: Each endpoint is a lightweight struct conforming to APIEndpoint.
/// The associated type `Response` tells the APIClient exactly what to decode.
/// No manual JSON parsing — the generic client handles it all.

struct PriceQuoteEndpoint: APIEndpoint {
    typealias Response = PriceResponse

    let symbol: String

    var path: String { "/price" }
    var queryItems: [URLQueryItem]? {
        [
            URLQueryItem(name: "symbol", value: symbol),
            URLQueryItem(name: "apikey", value: SecureAPIKeyManager.twelveDataAPIKey)
        ]
    }
}

/// Response DTO for price endpoint — Sendable for actor boundary crossing.
struct PriceResponse: Decodable, Sendable {
    let price: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // TwelveData returns price as a string
        if let stringPrice = try? container.decode(String.self, forKey: .price),
           let value = Double(stringPrice) {
            self.price = value
        } else {
            self.price = try container.decode(Double.self, forKey: .price)
        }
    }

    init(price: Double) {
        self.price = price
    }

    enum CodingKeys: String, CodingKey {
        case price
    }
}
