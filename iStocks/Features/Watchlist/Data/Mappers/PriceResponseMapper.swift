//
//  PriceResponseMapper.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-09.
//
import Foundation

enum PriceResponseMapper {
    static func map(data: Data) throws -> [Stock] {
        let decoded = try JSONDecoder().decode([String: StockPriceDTO].self, from: data)

        return decoded.compactMap { (symbol, dto) in
            dto.toStockPrice(symbol: symbol)
        }
    }
}
