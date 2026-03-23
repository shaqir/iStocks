//
//  WebBookmark.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2026-03-21.
//

import Foundation

/// Domain model representing a bookmarked web page for stock research
struct WebBookmark: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let url: URL
    let dateAdded: Date

    init(id: UUID = UUID(), title: String, url: URL, dateAdded: Date = Date()) {
        self.id = id
        self.title = title
        self.url = url
        self.dateAdded = dateAdded
    }
}
