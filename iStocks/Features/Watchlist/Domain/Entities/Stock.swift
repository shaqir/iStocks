//
//  Stock.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-30.
//
import Foundation

//The Domain Model: This is the model your app logic and UI should use.
struct Stock: Identifiable, Decodable, Equatable {
    
    var id: String { symbol } // Stable ID : // derive ID from symbol for uniqueness
    let symbol: String
    let name: String
    var price: Double              // Current market price
    let previousPrice: Double
    let isPriceUp: Bool

    let qty: Double                // Total quantity owned
    let averageBuyPrice: Double    // Weighted average buy price
    let sector: String

    let currency: String
    let exchange: String
    let isFavorite: Bool
   
    var invested: Double {
        qty * averageBuyPrice
    }

    var pnl: Double {
        (price * qty) - invested
    }

    var pnlPercentage: Double {
        guard invested != 0 else { return 0 }
        return (pnl / invested) * 100
    }

    var currentValue: Double {
        price * qty
    }

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
 
