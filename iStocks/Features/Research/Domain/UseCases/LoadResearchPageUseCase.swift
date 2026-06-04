//
//  LoadResearchPageUseCase.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Use case protocol for research page operations.
/// Follows the same pattern as Watchlist and Dashboard use cases
/// for architectural consistency across all features.
protocol LoadResearchPageUseCaseProtocol {
    func defaultURL() -> URL
    func isAllowedScheme(_ url: URL) -> Bool
}

/// Thin wrapper around ResearchRepositoryProtocol.
/// Exists for architectural consistency — every feature has Domain use cases
/// that ViewModels depend on, keeping the dependency direction clean:
/// Presentation → Domain → Data
nonisolated final class LoadResearchPageUseCase: LoadResearchPageUseCaseProtocol {

    private let repository: ResearchRepositoryProtocol

    init(repository: ResearchRepositoryProtocol) {
        self.repository = repository
    }

    func defaultURL() -> URL {
        repository.defaultURL()
    }

    func isAllowedScheme(_ url: URL) -> Bool {
        repository.isAllowedScheme(url)
    }
}
