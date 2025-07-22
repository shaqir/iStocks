//
//  ConnectionRetryManager.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-21.
//

import Foundation

final class ConnectionRetryManager {
    
    // MARK: - Properties
    private(set) var attempt = 0
    private let maxAttempts: Int
    private let maxDelay: TimeInterval
    private let baseDelay: TimeInterval
    private var workItem: DispatchWorkItem?
    
    init(maxAttempts: Int = 5, baseDelay: TimeInterval = 1, maxDelay: TimeInterval = 60) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
    }
    
    // MARK: - Retry Logic
    
    func scheduleRetry(taskName: String, on queue: DispatchQueue = .main, retryBlock: @escaping () -> Void) {
        guard attempt < maxAttempts else {
            Logger.log("[RetryManager] Max retry attempts reached for \(taskName).", category: "WebSocket")
            return
        }
        
        let delay = min(pow(2.0, Double(attempt)) * baseDelay, maxDelay)
        attempt += 1
        
        Logger.log("[RetryManager] Scheduling retry #\(attempt) for \(taskName) in \(delay) seconds", category: "WebSocket")
        
        workItem?.cancel()
        let item = DispatchWorkItem(block: retryBlock)
        workItem = item
        queue.asyncAfter(deadline: .now() + delay, execute: item)
    }
    
    func reset() {
        Logger.log("[RetryManager] Resetting retry state.", category: "WebSocket")
        attempt = 0
        workItem?.cancel()
        workItem = nil
    }
    
    var hasReachedMaxAttempts: Bool {
        attempt >= maxAttempts
    }
}
