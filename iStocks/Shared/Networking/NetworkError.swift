//
//  NetworkError.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case unauthorized
    case rateLimited
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .noData: return "No data received"
        case .unauthorized: return "API key is invalid or expired"
        case .rateLimited: return "Rate limit exceeded — try again shortly"
        case .serverError(let code): return "Server error (\(code))"
        }
    }
}
