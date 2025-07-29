//
//  FinnhubResponseMapper.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-28.
//
import Foundation
// MARK: - Finnhub Response Model
struct FinnhubResponseMapper: Decodable {
    let type: String
    let data: [Trade]?
    struct Trade: Decodable {
        let p: Double   // price
        let s: String   // symbol
        let t: TimeInterval // timestamp
    }
}
