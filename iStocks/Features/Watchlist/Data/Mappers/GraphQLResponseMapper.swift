//
//  GraphQLResponseMapper.swift
//  iStocks
//
//  Created by Sakir Saiyed.
//

import Foundation

/// Maps GraphQL DTOs to domain Stock entities
enum GraphQLResponseMapper {

    // MARK: - Map Array

    static func map(_ dtos: [StockGraphQLDTO]) -> [Stock] {
        dtos.compactMap { map($0) }
    }

    // MARK: - Map Single

    static func map(_ dto: StockGraphQLDTO) -> Stock? {
        guard let price = dto.price else {
            AppLogger.warning("Skipping \(dto.symbol) — missing price", category: AppLogger.network)
            return nil
        }

        let previousClose = dto.previousClose ?? price
        let isPriceUp = price >= previousClose

        return Stock(
            symbol: dto.symbol,
            name: dto.name ?? dto.symbol,
            price: price,
            previousPrice: previousClose,
            isPriceUp: isPriceUp,
            qty: 0,
            averageBuyPrice: price,
            sector: dto.sector ?? "Unknown",
            currency: dto.currency ?? "USD",
            exchange: dto.exchange ?? "NYSE",
            isFavorite: false
        )
    }
}
