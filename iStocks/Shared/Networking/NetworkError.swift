//
//  NetworkError.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import Foundation

/// Network-related errors with detailed context
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case unauthorized
    case rateLimited
    case serverError(Int)
    case timeout
    case noInternetConnection
    case cancelled
    case httpError(statusCode: Int, data: Data)
    case decodingFailed(Error)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: 
            return "Invalid URL"
        case .invalidResponse: 
            return "Invalid server response"
        case .noData: 
            return "No data received"
        case .unauthorized: 
            return "API key is invalid or expired"
        case .rateLimited: 
            return "Rate limit exceeded — try again shortly"
        case .serverError(let code): 
            return "Server error (\(code))"
        case .timeout:
            return "Request timed out"
        case .noInternetConnection:
            return "No internet connection available"
        case .cancelled:
            return "Request was cancelled"
        case .httpError(let statusCode, _):
            return "HTTP error (\(statusCode))"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unknown(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }

    var failureReason: String? {
        switch self {
        case .invalidURL:
            return "The URL provided is malformed"
        case .invalidResponse:
            return "The server returned an unexpected response format"
        case .noData:
            return "The server returned no data"
        case .unauthorized:
            return "Authentication failed"
        case .rateLimited:
            return "Too many requests sent in a short time"
        case .serverError(let code):
            return "Server returned error code \(code)"
        case .timeout:
            return "The request took too long to complete"
        case .noInternetConnection:
            return "Device is not connected to the internet"
        case .cancelled:
            return "User or system cancelled the request"
        case .httpError(let statusCode, _):
            return "Server returned HTTP status code \(statusCode)"
        case .decodingFailed:
            return "Response data format is invalid"
        case .unknown:
            return "An unexpected error occurred"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Contact support if this persists"
        case .invalidResponse, .noData:
            return "Try again later or contact support"
        case .unauthorized:
            return "Check your API key configuration"
        case .rateLimited:
            return "Wait a few minutes before trying again"
        case .serverError:
            return "Try again later or contact support"
        case .timeout:
            return "Check your internet connection and try again"
        case .noInternetConnection:
            return "Connect to the internet and try again"
        case .cancelled:
            return nil
        case .httpError:
            return "Try again later or contact support"
        case .decodingFailed:
            return "Update the app to the latest version"
        case .unknown:
            return "Try again later"
        }
    }

    /// Whether this error should be retried automatically
    var isRetryable: Bool {
        switch self {
        case .timeout, .serverError, .rateLimited, .noInternetConnection, .httpError:
            return true
        case .invalidURL, .invalidResponse, .noData, .unauthorized, .cancelled, .decodingFailed, .unknown:
            return false
        }
    }
}
