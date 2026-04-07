//
//  AppConstants.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-08.
//

import Foundation

/// NOTE (Swift 6.2): nonisolated because constants are used across all isolation contexts.
nonisolated enum AppConstants {
    static let maxStocksPerWatchlist = 10
    static let maxWatchlists = 10

    // MARK: - Timing
    static let heartbeatIntervalSeconds: TimeInterval = 10
    static let batchCollectionSeconds: TimeInterval = 1
    static let searchDebounceMilliseconds = 300
    static let priceAnimationDuration: TimeInterval = 0.5

    // MARK: - WebSocket
    static let maxWebSocketMessageQueueSize = 1000
}
