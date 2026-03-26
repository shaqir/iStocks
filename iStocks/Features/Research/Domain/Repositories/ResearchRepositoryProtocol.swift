//
//  ResearchRepositoryProtocol.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Domain-layer protocol for research page configuration.
/// Zero framework imports — pure business rules for URL handling.
protocol ResearchRepositoryProtocol {
    func defaultURL() -> URL
    func isAllowedScheme(_ url: URL) -> Bool
}
