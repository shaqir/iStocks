//
//  GraphQLError.swift
//  iStocks
//
//  Created by Sakir Saiyed.
//

import Foundation

// MARK: - GraphQL Error Detail

/// Represents a single error returned in the GraphQL response `errors` array
nonisolated struct GraphQLErrorDetail: Decodable, Equatable {
    let message: String
    let locations: [GraphQLErrorLocation]?
    let path: [String]?
}

nonisolated struct GraphQLErrorLocation: Decodable, Equatable {
    let line: Int
    let column: Int
}

// MARK: - GraphQL Error

/// Domain-level errors specific to GraphQL operations
nonisolated enum GraphQLError: LocalizedError {
    case queryFailed(String)
    case invalidResponse
    case graphQLErrors([GraphQLErrorDetail])
    case encodingFailed
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .queryFailed(let message):
            return "GraphQL query failed: \(message)"
        case .invalidResponse:
            return "Invalid GraphQL response format"
        case .graphQLErrors(let errors):
            let messages = errors.map(\.message).joined(separator: "; ")
            return "GraphQL errors: \(messages)"
        case .encodingFailed:
            return "Failed to encode GraphQL query"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
