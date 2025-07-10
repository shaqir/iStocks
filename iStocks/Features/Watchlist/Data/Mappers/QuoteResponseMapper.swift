//
//  QuoteResponseMapper.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-09.
//

import Foundation

enum QuoteResponseMapper {
    static func map(_ responseDict: [String: StockResponseWrapper]) throws -> [Stock] {
        var validStocks: [Stock] = []
        var errorMessages: [String] = []

        for (symbol, result) in responseDict {
            switch result {
            case .success(let response):
                if let stock = response.toDomainModel(invested: Double.random(in: 50000...100000)) {
                    validStocks.append(stock)
                }
            case .error(let apiError):
                errorMessages.append("\(symbol): \(apiError.errorDescription ?? "Unknown error")")
            }
        }

        if validStocks.isEmpty {
            throw TwelveDataAPIError.invalidSymbols(errorMessages)
        }

        return validStocks
    }
}
