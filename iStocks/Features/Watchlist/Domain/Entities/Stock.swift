//
//  Stock.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-30.
//
import Foundation

/// Domain model representing a stock with price, holdings, and P&L calculations
///
/// This is the core business entity used throughout the app.
/// Immutable except for price updates which create new instances.
///
/// Example:
/// ```swift
/// let stock = Stock(
///     symbol: "AAPL",
///     name: "Apple Inc.",
///     price: 150.0,
///     previousPrice: 148.0,
///     isPriceUp: true,
///     qty: 10,
///     averageBuyPrice: 145.0,
///     sector: "Technology",
///     currency: "USD",
///     exchange: "NASDAQ",
///     isFavorite: false
/// )
/// print(stock.pnl) // Profit/Loss: 50.0
/// ```
struct Stock: Identifiable, Codable, Equatable {
    
    /// Unique identifier derived from stock symbol
    var id: String { symbol }
    
    /// Stock ticker symbol (e.g., "AAPL", "GOOGL")
    let symbol: String
    
    /// Company or stock name
    let name: String
    
    /// Current market price
    var price: Double
    
    /// Previous price for change calculation
    let previousPrice: Double
    
    /// Whether the price increased from previous
    let isPriceUp: Bool

    /// Total quantity owned
    let qty: Double
    
    /// Weighted average buy price per share
    let averageBuyPrice: Double
    
    /// Stock sector (e.g., "Technology", "Finance")
    let sector: String

    /// Currency code (e.g., "USD", "EUR")
    let currency: String
    
    /// Exchange name (e.g., "NASDAQ", "NYSE")
    let exchange: String
    
    /// Whether marked as favorite by user
    let isFavorite: Bool
   
    /// Total amount invested (quantity × average buy price)
    var invested: Double {
        qty * averageBuyPrice
    }

    /// Profit & Loss in currency units
    var pnl: Double {
        (price * qty) - invested
    }

    /// Profit & Loss as a percentage of investment
    var pnlPercentage: Double {
        guard invested != 0 else { return 0 }
        return (pnl / invested) * 100
    }

    /// Current market value of holdings
    var currentValue: Double {
        price * qty
    }

    /// Whether price has changed from previous value
    var hasPriceChanged: Bool {
        price != previousPrice
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
            name: "Technology",
            price: 123.45,
            previousPrice: 120.0,
            isPriceUp: true,
            qty: 10,
            averageBuyPrice: 100.0,
            sector: "Technology",
            currency: "$",
            exchange: "NASDAQ",
            isFavorite: false
        )
    }
    
    func updatedPrice(_ newPrice: Double) -> Stock {
        Stock(
            symbol: self.symbol,
            name: self.name,
            price: newPrice,
            previousPrice: self.price,
            isPriceUp: newPrice >= self.price,
            qty: self.qty,
            averageBuyPrice: self.averageBuyPrice,
            sector: self.sector,
            currency: self.currency,
            exchange: self.exchange,
            isFavorite: self.isFavorite
            
        )
    }
    
    func copyWith(
        symbol: String? = nil,
        name: String? = nil,
        price: Double? = nil,
        previousPrice: Double? = nil,
        isPriceUp: Bool? = nil,
        qty: Int? = nil,
        averageBuyPrice: Double? = nil,
        sector: String? = nil,
        currency: String? = nil,
        exchange: String? = nil,
        isFavorite: Bool? = nil
    ) -> Stock {
        return Stock(
            symbol: symbol ?? self.symbol,
            name: name ?? self.name,
            price: price ?? self.price,
            previousPrice: previousPrice ?? self.previousPrice,
            isPriceUp: isPriceUp ?? self.isPriceUp,
            qty: Double(qty ?? Int(self.qty)),
            averageBuyPrice: averageBuyPrice ?? self.averageBuyPrice,
            sector: sector ?? self.sector,
            currency: currency ?? self.currency,
            exchange: exchange ?? self.exchange,
            isFavorite: isFavorite ?? self.isFavorite
        )
    }
    
    static func mock(symbol: String = "MOCK") -> Stock {
        Stock(
            symbol: symbol,
            name: symbol,
            price: 100,
            previousPrice: 90,
            isPriceUp: true,
            qty: 0,
            averageBuyPrice: 0,
            sector: "Tech",
            currency: "USD",
            exchange: "NASDAQ",
            isFavorite: false
        )
    }
}
 
