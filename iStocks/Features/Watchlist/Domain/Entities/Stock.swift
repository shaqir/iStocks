//
//  Stock.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-30.
//
import Foundation

/// Domain model representing a stock with market price data.
///
/// Contains only data that APIs actually provide — market prices, exchange info,
/// and sector classification. Portfolio data (qty, averageBuyPrice) belongs in
/// the Dashboard's Holding entity where real position data is available.
struct Stock: Identifiable, Codable, Equatable {
    
    /// Unique identifier derived from stock symbol
    var id: String { symbol }
    
    /// Stock ticker symbol (e.g., "AAPL", "GOOGL")
    let symbol: String
    
    /// Company or stock name
    let name: String
    
    /// Current market price
    var price: Double
    
    /// Previous closing price for change calculation
    let previousPrice: Double
    
    /// Whether the price increased from previous close
    let isPriceUp: Bool

    /// Stock sector (e.g., "Technology", "Financials")
    let sector: String

    /// Currency code (e.g., "USD", "EUR")
    let currency: String
    
    /// Exchange name (e.g., "NASDAQ", "NYSE")
    let exchange: String

    /// Whether price has changed from previous value
    var hasPriceChanged: Bool { price != previousPrice }

    /// Price change as a percentage of previous close
    var priceChangePercentage: Double {
        guard previousPrice != 0 else { return 0 }
        return ((price - previousPrice) / previousPrice) * 100
    }
}

extension Stock {
    
    var priceChangeText: String {
        let diff = price - previousPrice
        return String(format: "%@%.2f", diff >= 0 ? "+" : "", diff)
    }
    
    static func dummy() -> Stock {
        Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            price: 123.45,
            previousPrice: 120.0,
            isPriceUp: true,
            sector: "Technology",
            currency: "USD",
            exchange: "NASDAQ"
        )
    }
    
    func updatedPrice(_ newPrice: Double) -> Stock {
        Stock(
            symbol: self.symbol,
            name: self.name,
            price: newPrice,
            previousPrice: self.price,
            isPriceUp: newPrice >= self.price,
            sector: self.sector,
            currency: self.currency,
            exchange: self.exchange
        )
    }
    
    func copyWith(
        symbol: String? = nil,
        name: String? = nil,
        price: Double? = nil,
        previousPrice: Double? = nil,
        isPriceUp: Bool? = nil,
        sector: String? = nil,
        currency: String? = nil,
        exchange: String? = nil
    ) -> Stock {
        return Stock(
            symbol: symbol ?? self.symbol,
            name: name ?? self.name,
            price: price ?? self.price,
            previousPrice: previousPrice ?? self.previousPrice,
            isPriceUp: isPriceUp ?? self.isPriceUp,
            sector: sector ?? self.sector,
            currency: currency ?? self.currency,
            exchange: exchange ?? self.exchange
        )
    }
    
    static func mock(symbol: String = "MOCK") -> Stock {
        Stock(
            symbol: symbol,
            name: symbol,
            price: 100,
            previousPrice: 90,
            isPriceUp: true,
            sector: "Tech",
            currency: "USD",
            exchange: "NASDAQ"
        )
    }
}
