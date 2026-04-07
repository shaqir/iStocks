//
//  News.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Domain model representing a financial news article.
/// NOTE (Swift 6.2): nonisolated — domain entities must work across all isolation contexts.
nonisolated struct News: Identifiable, Codable, Sendable {

    let id: UUID
    let headline: String
    let source: String
    let url: URL
    let publishedAt: Date
    let relatedSymbols: [String]

    // MARK: - Mock

    static func mock(
        headline: String = "Apple Reports Record Q4 Revenue",
        source: String = "Reuters"
    ) -> News {
        News(
            id: UUID(),
            headline: headline,
            source: source,
            url: URL(string: "https://example.com/news")!,
            publishedAt: Date(),
            relatedSymbols: ["AAPL"]
        )
    }
}
