//
//  Logger.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-15.
//

import Foundation
import OSLog

/// Production-grade logging system using os.Logger
/// Provides structured logging with different levels and automatic log filtering
enum AppLogger {
    
    // MARK: - Subsystem
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.iStocks"
    
    // MARK: - Log Levels
    enum Level {
        case debug
        case info
        case notice
        case warning
        case error
        case fault
    }
    
    // MARK: - Category Loggers
    static let general = OSLog(subsystem: subsystem, category: "General")
    static let network = OSLog(subsystem: subsystem, category: "Network")
    static let webSocket = OSLog(subsystem: subsystem, category: "WebSocket")
    static let persistence = OSLog(subsystem: subsystem, category: "Persistence")
    static let viewModel = OSLog(subsystem: subsystem, category: "ViewModel")
    static let di = OSLog(subsystem: subsystem, category: "DI")
    static let startup = OSLog(subsystem: subsystem, category: "Startup")
    static let ui = OSLog(subsystem: subsystem, category: "UI")
    static let webView = OSLog(subsystem: subsystem, category: "WebView")
    
    // MARK: - Logging Methods
    
    /// Log a debug message (only visible in debug builds)
    static func debug(_ message: String, category: OSLog = AppLogger.general, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        os_log(.debug, log: category, "%{public}@", message)
        #endif
    }
    
    /// Log an informational message
    static func info(_ message: String, category: OSLog = AppLogger.general) {
        os_log(.info, log: category, "%{public}@", message)
    }
    
    /// Log a notice (significant but not problematic)
    static func notice(_ message: String, category: OSLog = AppLogger.general) {
        os_log(.default, log: category, "%{public}@", message)
    }
    
    /// Log a warning (potential issue)
    static func warning(_ message: String, category: OSLog = AppLogger.general) {
        os_log(.error, log: category, "⚠️ %{public}@", message)
    }
    
    /// Log an error
    static func error(_ message: String, category: OSLog = AppLogger.general, error: Error? = nil) {
        if let error = error {
            os_log(.error, log: category, "❌ %{public}@ - Error: %{public}@", message, error.localizedDescription)
        } else {
            os_log(.error, log: category, "❌ %{public}@", message)
        }
    }
    
    /// Log a critical fault (system-level failure)
    static func fault(_ message: String, category: OSLog = AppLogger.general, error: Error? = nil) {
        if let error = error {
            os_log(.fault, log: category, "🔥 %{public}@ - Error: %{public}@", message, error.localizedDescription)
        } else {
            os_log(.fault, log: category, "🔥 %{public}@", message)
        }
    }
}

// MARK: - Legacy Logger Compatibility
// Provides backward compatibility for existing code
@available(*, deprecated, message: "Use AppLogger instead")
enum Logger {
    static var isEnabled = true

    static func log(_ message: String, category: String = "General") {
        guard isEnabled else { return }
        
        // Map to new logger
        let osCategory: OSLog = {
            switch category.lowercased() {
            case "network": return AppLogger.network
            case "websocket": return AppLogger.webSocket
            case "persistence": return AppLogger.persistence
            case "viewmodel", "watchlistsvm": return AppLogger.viewModel
            case "di": return AppLogger.di
            case "startup": return AppLogger.startup
            case "ui": return AppLogger.ui
            default: return AppLogger.general
            }
        }()
        
        AppLogger.info(message, category: osCategory)
    }
}
