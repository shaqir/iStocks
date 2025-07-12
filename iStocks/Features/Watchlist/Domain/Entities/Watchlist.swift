//
//  Watchlist.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import Foundation

struct Watchlist: Identifiable, Equatable {
    let id: UUID
    var name: String
    var stocks: [Stock]
    
    init(id: UUID, name: String, stocks: [Stock]) {
        self.id = id
        self.name = name
        self.stocks = stocks
    }
}
//Watchlist (Domain Layer): Pure data model with validation logic.
extension Watchlist {
    
    var hasDuplicateSymbols: Bool {
        Set(stocks.map { $0.symbol }).count != stocks.count
    }
    
    var isEmpty: Bool {
        stocks.isEmpty
    }
    
    mutating func replaceAllStocks(_ newStocks: [Stock]) throws {
        if newStocks.count > AppConstants.maxStocksPerWatchlist {
            throw StockValidationError.limitReached(num: AppConstants.maxStocksPerWatchlist)
        }
        let unique = Set(newStocks.map { $0.symbol })
        if unique.count != newStocks.count {
            throw StockValidationError.duplicate
        }
        self.stocks = newStocks
    }
    
    mutating func replacePrices(from updatedStocks: [Stock]) {
        let priceMap = Dictionary(uniqueKeysWithValues: updatedStocks.map { ($0.symbol, $0.price) })

        guard !priceMap.isEmpty else {
            print("No prices to update")
            return
        }

        for i in stocks.indices {
            if let newPrice = priceMap[stocks[i].symbol] {
                stocks[i].price = newPrice
            }
        }
    }
    
    mutating func tryAddStock(_ stock: Stock) throws {
        if stocks.count >= AppConstants.maxStocksPerWatchlist {
            print("tryAddStock.....limit reached")
            throw StockValidationError.limitReached(num: AppConstants.maxStocksPerWatchlist)
        }
        if stock.symbol.isEmpty {
            throw StockValidationError.invalidSymbol
        }
        
        if stocks.contains(where: { $0.symbol == stock.symbol }) {
            throw StockValidationError.duplicate
        }
        stocks.append(stock)
    }
    
    mutating func tryRemoveStock(_ stock: Stock) throws {
        guard let index = stocks.firstIndex(where: { $0.symbol == stock.symbol }) else {
            throw StockValidationError.notFound
        }
        stocks.remove(at: index)
    }
}

extension Watchlist {
    static func empty() -> Watchlist {
        Watchlist(id: UUID(), name: "", stocks: [])
    }
}
