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
}

extension Stock {
    static func dummy() -> Stock {
        Stock(
            symbol: "AAPL",
            name: "Technology",
            price: 123.45,
            previousPrice: 120.0,
            isPriceUp: true,
            qty: 10,
            averageBuyPrice: 100.0, 
            sector: "Technology"
        )
    }
}
 

extension Stock {
    func updatedPrice(_ newPrice: Double) -> Stock {
        Stock(
            symbol: self.symbol,
            name: self.name,
            price: newPrice,
            previousPrice: self.price,
            isPriceUp: newPrice >= self.price,
            qty: self.qty,
            averageBuyPrice: self.averageBuyPrice,
            sector: self.sector
        )
    }
}
