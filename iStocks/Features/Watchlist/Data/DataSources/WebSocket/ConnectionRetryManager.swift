//
//  ConnectionRetryManager.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-21.
//

import Foundation

/// Actor-based retry manager using structured concurrency.
///
/// Migration (Swift 6.2): Replaced DispatchQueue.asyncAfter with Task.sleep.
/// The actor isolation protects mutable retry state (attempt count, active task)
/// from data races — previously relied on "always call from main queue" convention.
///
/// Key design decisions:
/// - `Task.sleep` is cancellation-aware: cancelling the task cancels the sleep
/// - Previous DispatchWorkItem.cancel() only prevented execution — didn't cancel in-flight work
/// - `@Sendable` closure requirement enforces that retry blocks are safe to call from any context
actor ConnectionRetryManager {

    // MARK: - Properties
    private(set) var attempt = 0
    private let maxAttempts: Int
    private let maxDelay: TimeInterval
    private let baseDelay: TimeInterval
    private var retryTask: Task<Void, Never>?

    init(maxAttempts: Int = 5, baseDelay: TimeInterval = 1, maxDelay: TimeInterval = 60) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
    }

    // MARK: - Retry Logic

    /// Schedules a retry with exponential backoff using structured concurrency.
    ///
    /// Backoff schedule (default config):
    ///   Attempt 0: 1s, Attempt 1: 2s, Attempt 2: 4s, Attempt 3: 8s, Attempt 4: 16s
    ///
    /// - Parameters:
    ///   - taskName: Identifier for logging
    ///   - retryBlock: The operation to retry — must be @Sendable since it crosses isolation boundaries
    func scheduleRetry(taskName: String, retryBlock: @Sendable @escaping () async -> Void) {
        guard attempt < maxAttempts else {
            AppLogger.warning("Max retry attempts reached for \(taskName)", category: AppLogger.webSocket)
            return
        }

        let delay = min(pow(2.0, Double(attempt)) * baseDelay, maxDelay)
        attempt += 1

        if attempt > 2 {
            AppLogger.warning("Retry #\(attempt) for \(taskName) in \(delay)s", category: AppLogger.webSocket)
        }

        retryTask?.cancel()
        retryTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            await retryBlock()
        }
    }

    func reset() {
        attempt = 0
        retryTask?.cancel()
        retryTask = nil
    }

    var hasReachedMaxAttempts: Bool {
        attempt >= maxAttempts
    }
}
