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

extension Watchlist {
    
    var hasDuplicateSymbols: Bool {
        Set(stocks.map { $0.symbol }).count != stocks.count
    }

    var isEmpty: Bool {
        stocks.isEmpty
    }
    
    mutating func tryAddStock(_ stock: Stock) throws {
        if stocks.count >= 10 {
            throw StockValidationError.limitReached(num: 10)
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
        guard let index = stocks.firstIndex(where: { $0.id == stock.id }) else {
            throw StockValidationError.notFound
        }
        stocks.remove(at: index)
    }
    
}
 
