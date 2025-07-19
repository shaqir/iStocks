//
//  QuoteEndPoint.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-18.
//

import Foundation

struct QuoteEndPoint {
    static func forSymbols(_ symbols: [String], apiKey: String) -> Endpoint {
        return Endpoint(
            path: "/quote",  // use /quote for multiple symbols
            method: .get,
            queryItems: [
                URLQueryItem(name: "symbol", value: symbols.joined(separator: ",")),
                URLQueryItem(name: "apikey", value: apiKey)
            ]
        )
    }
}
