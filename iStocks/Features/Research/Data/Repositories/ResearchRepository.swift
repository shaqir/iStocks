//
//  ResearchRepository.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Concrete implementation of research configuration.
/// Centralizes URL validation and default page logic that was previously
/// scattered across the ViewModel and WebView coordinator.
final class ResearchRepository: ResearchRepositoryProtocol {

    private let allowedSchemes: Set<String> = ["https", "http"]

    func defaultURL() -> URL {
        URL(string: "https://finance.yahoo.com")!
    }

    func isAllowedScheme(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return allowedSchemes.contains(scheme)
    }
}
