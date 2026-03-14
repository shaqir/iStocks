//
//  AppError.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import Foundation

/// Application-level errors with detailed context and recovery suggestions
enum AppError: LocalizedError {
    case network(NetworkError)
    case api(message: String)
    case persistence(PersistenceError)
    case validation(ValidationError)
    case webSocket(WebSocketError)
    case configuration(ConfigurationError)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .network(let error): 
            return error.localizedDescription
        case .api(let message): 
            return "API Error: \(message)"
        case .persistence(let error): 
            return error.localizedDescription
        case .validation(let error): 
            return error.localizedDescription
        case .webSocket(let error): 
            return error.localizedDescription
        case .configuration(let error): 
            return error.localizedDescription
        case .unknown(let error): 
            return "Unexpected error: \(error.localizedDescription)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .network(let error): 
            return error.failureReason
        case .api: 
            return "The API returned an error"
        case .persistence(let error): 
            return error.failureReason
        case .validation(let error): 
            return error.failureReason
        case .webSocket(let error): 
            return error.failureReason
        case .configuration(let error): 
            return error.failureReason
        case .unknown: 
            return "An unexpected error occurred"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .network(let error): 
            return error.recoverySuggestion
        case .api: 
            return "Try again later or contact support"
        case .persistence(let error): 
            return error.recoverySuggestion
        case .validation(let error): 
            return error.recoverySuggestion
        case .webSocket(let error): 
            return error.recoverySuggestion
        case .configuration(let error): 
            return error.recoverySuggestion
        case .unknown: 
            return "Try restarting the app"
        }
    }
}

// MARK: - Persistence Errors

enum PersistenceError: LocalizedError {
    case saveFailed(Error)
    case loadFailed(Error)
    case deleteFailed(Error)
    case invalidData
    case migrationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error): 
            return "Failed to save data: \(error.localizedDescription)"
        case .loadFailed(let error): 
            return "Failed to load data: \(error.localizedDescription)"
        case .deleteFailed(let error): 
            return "Failed to delete data: \(error.localizedDescription)"
        case .invalidData: 
            return "Data is corrupted or invalid"
        case .migrationFailed(let error): 
            return "Failed to migrate data: \(error.localizedDescription)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .saveFailed, .loadFailed, .deleteFailed:
            return "Database operation failed"
        case .invalidData:
            return "Stored data format is invalid"
        case .migrationFailed:
            return "Data schema migration failed"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .saveFailed:
            return "Try again or free up storage space"
        case .loadFailed:
            return "Try restarting the app"
        case .deleteFailed:
            return "Try again later"
        case .invalidData:
            return "Clear app data and try again"
        case .migrationFailed:
            return "Reinstall the app to fix data issues"
        }
    }
}

// MARK: - Validation Errors

enum ValidationError: LocalizedError {
    case invalidSymbol(String)
    case invalidPrice
    case invalidQuantity
    case duplicateEntry
    case limitExceeded(limit: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidSymbol(let symbol): 
            return "Invalid stock symbol: \(symbol)"
        case .invalidPrice: 
            return "Price must be greater than zero"
        case .invalidQuantity: 
            return "Quantity must be greater than zero"
        case .duplicateEntry: 
            return "This entry already exists"
        case .limitExceeded(let limit): 
            return "Maximum limit of \(limit) exceeded"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidSymbol:
            return "Symbol format is invalid"
        case .invalidPrice, .invalidQuantity:
            return "Value is out of valid range"
        case .duplicateEntry:
            return "Entry already exists"
        case .limitExceeded:
            return "Too many items"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidSymbol:
            return "Enter a valid stock symbol"
        case .invalidPrice, .invalidQuantity:
            return "Enter a positive number"
        case .duplicateEntry:
            return "Remove the duplicate or edit the existing entry"
        case .limitExceeded:
            return "Delete some entries before adding new ones"
        }
    }
}

// MARK: - WebSocket Errors

enum WebSocketError: LocalizedError {
    case connectionFailed(Error)
    case invalidURL
    case disconnected
    case sendFailed(Error)
    case receiveFailed(Error)
    case invalidMessage
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed(let error): 
            return "Failed to connect: \(error.localizedDescription)"
        case .invalidURL: 
            return "Invalid WebSocket URL"
        case .disconnected: 
            return "WebSocket connection closed"
        case .sendFailed(let error): 
            return "Failed to send message: \(error.localizedDescription)"
        case .receiveFailed(let error): 
            return "Failed to receive message: \(error.localizedDescription)"
        case .invalidMessage: 
            return "Received invalid message format"
        case .authenticationFailed: 
            return "WebSocket authentication failed"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .connectionFailed:
            return "Could not establish connection"
        case .invalidURL:
            return "URL is malformed"
        case .disconnected:
            return "Connection was closed"
        case .sendFailed, .receiveFailed:
            return "Communication error"
        case .invalidMessage:
            return "Message format is invalid"
        case .authenticationFailed:
            return "Invalid credentials"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .connectionFailed, .disconnected:
            return "Check your internet connection and try again"
        case .invalidURL:
            return "Contact support"
        case .sendFailed, .receiveFailed:
            return "Reconnect and try again"
        case .invalidMessage:
            return "Update the app to the latest version"
        case .authenticationFailed:
            return "Check your API key configuration"
        }
    }
}

// MARK: - Configuration Errors

enum ConfigurationError: LocalizedError {
    case missingAPIKey
    case invalidAPIKey
    case missingConfiguration(String)
    case invalidConfiguration(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey: 
            return "API key is missing"
        case .invalidAPIKey: 
            return "API key is invalid"
        case .missingConfiguration(let key): 
            return "Missing configuration: \(key)"
        case .invalidConfiguration(let key): 
            return "Invalid configuration: \(key)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .missingAPIKey, .invalidAPIKey:
            return "API key is not properly configured"
        case .missingConfiguration, .invalidConfiguration:
            return "App configuration is incomplete"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .missingAPIKey:
            return "Add your API key to the configuration"
        case .invalidAPIKey:
            return "Check your API key and try again"
        case .missingConfiguration, .invalidConfiguration:
            return "Reinstall the app or contact support"
        }
    }
}
