//
//  PriceEndPoint.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-09.
//

import Foundation

nonisolated struct PriceEndpoint {
    static func forSymbols(_ symbols: [String], apiKey: String) -> Endpoint {
        return Endpoint(
            path: "/price",
            method: .get,
            queryItems: [
                URLQueryItem(name: "symbol", value: symbols.joined(separator: ",")),
                URLQueryItem(name: "apikey", value: apiKey)
            ]
        )
    }
}
 
