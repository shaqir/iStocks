//
//  AppConfiguration.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Application configuration management
/// Provides environment-based settings with build configuration support
enum AppConfiguration {
    
    // MARK: - Environment
    
    enum Environment {
        case development
        case staging
        case production
        
        static var current: Environment {
            #if DEBUG
            return .development
            #elseif STAGING
            return .staging
            #else
            return .production
            #endif
        }
        
        var displayName: String {
            switch self {
            case .development: return "Development"
            case .staging: return "Staging"
            case .production: return "Production"
            }
        }
    }
    
    // MARK: - App Mode
    
    static var watchlistMode: WatchlistAppMode {
        #if DEBUG
        // In debug builds, use mock data by default
        return ProcessInfo.processInfo.environment["WATCHLIST_MODE"].flatMap { mode in
            switch mode.lowercased() {
            case "rest": return .restAPI
            case "websocket": return .websocket
            case "graphql": return .graphQL
            default: return .mock
            }
        } ?? .mock
        #else
        // In release builds, use REST API
        return .restAPI
        #endif
    }
    
    // MARK: - Logging
    
    static var isLoggingEnabled: Bool {
        #if DEBUG
        return true
        #else
        return Environment.current != .production
        #endif
    }
    
    static var verboseLogging: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - API Configuration
    
    static var apiTimeout: TimeInterval {
        switch Environment.current {
        case .development: return 30.0
        case .staging: return 20.0
        case .production: return 15.0
        }
    }
    
    static var maxRetryAttempts: Int {
        switch Environment.current {
        case .development: return 5
        case .staging: return 3
        case .production: return 2
        }
    }
    
    // MARK: - Feature Flags
    
    static var isWebSocketEnabled: Bool {
        #if DEBUG
        return true
        #else
        return false // Disable WebSocket in production until fully tested
        #endif
    }
    
    static var isMockDataEnabled: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Debug Helpers
    
    static var isRunningTests: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
    
    static func printConfiguration() {
        AppLogger.info("=== App Configuration ===", category: AppLogger.startup)
        AppLogger.info("Environment: \(Environment.current.displayName)", category: AppLogger.startup)
        AppLogger.info("Watchlist Mode: \(watchlistMode)", category: AppLogger.startup)
        AppLogger.info("Logging Enabled: \(isLoggingEnabled)", category: AppLogger.startup)
        AppLogger.info("WebSocket Enabled: \(isWebSocketEnabled)", category: AppLogger.startup)
        AppLogger.info("Running Tests: \(isRunningTests)", category: AppLogger.startup)
        AppLogger.info("========================", category: AppLogger.startup)
    }
}
