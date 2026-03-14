//
//  QuoteResponseMapper.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-09.
//

import Foundation
///Maps valid stocks and logs or throws on failure
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

        if validStocks.isEmpty && !errorMessages.isEmpty {
            AppLogger.error("Valid Stocks empty and errorMessages not empty", category: AppLogger.network)
            throw TwelveDataAPIError.invalidSymbols(errorMessages)
        }

        if !errorMessages.isEmpty {
            AppLogger.warning("Quote mapping errors: \(errorMessages.joined(separator: ", "))", category: AppLogger.network)
        }

        // Always throw if no valid stocks returned
        if validStocks.isEmpty {
            AppLogger.error("Valid Stocks Empty", category: AppLogger.network)
            throw AppError.api(message: "Invalid or empty response for symbols.")
        }

        AppLogger.debug("Successfully mapped \(validStocks.count) valid stocks", category: AppLogger.network)
        return validStocks
    }
}

///Allows decoding of both object and dictionary forms
enum StockQuoteDynamicResponse: Decodable {
    case dictionary([String: StockResponseWrapper])
    case single(StockResponseWrapper)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let dict = try? container.decode([String: StockResponseWrapper].self) {
            self = .dictionary(dict)
        } else if let single = try? container.decode(StockResponseWrapper.self) {
            self = .single(single)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unexpected JSON structure for quote response"
            )
        }
    }
}
