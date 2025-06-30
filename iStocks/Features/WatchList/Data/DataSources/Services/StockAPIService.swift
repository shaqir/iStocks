//
//  ✅ StockAPIService.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import Foundation
import Combine

// MARK: - Protocol for abstraction
protocol StockServiceProtocol {
    func getWatchlistStocks() -> AnyPublisher<[Stock], Error>
}

// MARK: - API Mode Enum
enum StockServiceMode {
    case live
    case mock
}

// MARK: - Main Service
//Concrete API implementation (live).
//Fetches live data using Combine.
final class StockAPIService: StockServiceProtocol {
    
    static let shared = StockAPIService()
    
    private let mode: StockServiceMode
    private let apiKey = "YOUR_API_KEY" //https://api.twelvedata.com
    private let symbols = ["AAPL", "TSLA", "MSFT", "GOOGL"]
    
    private init(mode: StockServiceMode = .mock) {  // Change to `.live` for real API
        self.mode = mode
    }

    func getWatchlistStocks() -> AnyPublisher<[Stock], any Error> {
        switch mode {
        case .mock:
            return Just(MockData.sampleStocks)
                .delay(for: .seconds(2), scheduler: DispatchQueue.main)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            
        case .live:
            let publishers = symbols.map { fetchStock(symbol: $0) }
            
            return Publishers.MergeMany(publishers)
                .collect()
                .replaceError(with: [])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }

    private func fetchStock(symbol: String) -> AnyPublisher<Stock, Error> {
        let urlString = "https://api.twelvedata.com/quote?symbol=\(symbol)&apikey=\(apiKey)"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: StockAPIResponse.self, decoder: JSONDecoder())
            .map { response in
                Stock(
                    symbol: response.symbol,
                    ltp: Double(response.price) ?? 0,
                    change: Double(response.change) ?? 0,
                    percentChange: Double(response.percent_change.replacingOccurrences(of: "%", with: "")) ?? 0,
                    invested: 100000,
                    currentValue: 100000 + (Double(response.change) ?? 0) * 100, groupName: "Needs to be implemented"
                )
            }
            .eraseToAnyPublisher()
    }
}
