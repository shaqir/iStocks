//
//  StockAPIResponseOrError.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-01.
//

import Foundation
enum StockResponseWrapper: Decodable {
   
    case success(StockDTO)
    case error(TwelveDataAPIError)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let error = try? container.decode(TwelveDataAPIError.self) {
            self = .error(error)
        } else {
            let stock = try container.decode(StockDTO.self)
            self = .success(stock)
        }
    }
}
