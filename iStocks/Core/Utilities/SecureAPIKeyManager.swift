//
//  SecureAPIKeyManager.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Secure API key management
/// Retrieves API keys from environment variables or secure storage
nonisolated enum SecureAPIKeyManager {
    
    // MARK: - API Keys
    
    /// Finnhub API key
    static var finnhubAPIKey: String {
        // Priority: Environment variable > Info.plist > Fallback
        if let envKey = ProcessInfo.processInfo.environment["FINNHUB_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        if let plistKey = Bundle.main.infoDictionary?["FINNHUB_API_KEY"] as? String, !plistKey.isEmpty {
            return plistKey
        }
        
        AppLogger.warning("Finnhub API key not configured", category: AppLogger.general)
        return "" // Return empty string instead of crash
    }
    
    /// Twelve Data API key
    static var twelveDataAPIKey: String {
        if let envKey = ProcessInfo.processInfo.environment["TWELVE_DATA_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        if let plistKey = Bundle.main.infoDictionary?["TWELVE_DATA_API_KEY"] as? String, !plistKey.isEmpty {
            return plistKey
        }
        
        AppLogger.warning("Twelve Data API key not configured", category: AppLogger.general)
        return ""
    }
    
    // MARK: - Validation
    
    /// Check if Finnhub API key is configured
    static var isFinnhubConfigured: Bool {
        !finnhubAPIKey.isEmpty
    }
    
    /// Check if Twelve Data API key is configured
    static var isTwelveDataConfigured: Bool {
        !twelveDataAPIKey.isEmpty
    }
    
    /// Validate all API keys are properly configured
    static func validateConfiguration() throws {
        var missingKeys: [String] = []
        
        if !isFinnhubConfigured {
            missingKeys.append("Finnhub API Key")
        }
        
        if !isTwelveDataConfigured {
            missingKeys.append("Twelve Data API Key")
        }
        
        if !missingKeys.isEmpty {
            AppLogger.error("Missing API keys: \(missingKeys.joined(separator: ", "))", category: AppLogger.general)
            throw ConfigurationError.missingConfiguration("API Keys: \(missingKeys.joined(separator: ", "))")
        }
    }
    
    // MARK: - Debug Info
    
    static func printConfigurationStatus() {
        #if DEBUG
        AppLogger.debug("=== API Key Configuration ===", category: AppLogger.startup)
        AppLogger.debug("Finnhub: \(isFinnhubConfigured ? "✓ Configured" : "✗ Missing")", category: AppLogger.startup)
        AppLogger.debug("Twelve Data: \(isTwelveDataConfigured ? "✓ Configured" : "✗ Missing")", category: AppLogger.startup)
        AppLogger.debug("============================", category: AppLogger.startup)
        #endif
    }
}
