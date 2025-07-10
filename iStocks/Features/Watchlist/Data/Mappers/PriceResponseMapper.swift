//
//  PriceResponseMapper.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-09.
//
import Foundation

enum PriceResponseMapper {
    static func map(_ responseDict: [String: StockPriceDTO]) -> [Stock] {
        return responseDict.compactMap { (symbol, dto) in
            dto.toStockPrice(symbol: symbol)
        }
    }
}
