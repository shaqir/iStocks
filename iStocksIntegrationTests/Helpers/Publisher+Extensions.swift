//
//  Publisher+Extensions.swift
//  iStocksIntegrationTests
//
//  Created by Sakir Saiyed on 2025-07-23.
//

import Foundation
internal import Combine

extension Publisher where Output: Sendable {
    func asyncValues() async throws -> [Output] {
        // NOTE: The cancellable must be declared OUTSIDE the continuation closure
        // so it stays alive until the continuation resumes. If it's deallocated early,
        // the subscription is cancelled and no values arrive.
        nonisolated(unsafe) var cancellable: AnyCancellable?
        return try await withCheckedThrowingContinuation { continuation in
            nonisolated(unsafe) var collected: [Output] = []
            nonisolated(unsafe) var didResume = false
            cancellable = self
                .sink(receiveCompletion: { completion in
                    guard !didResume else { return }
                    didResume = true
                    switch completion {
                    case .finished:
                        continuation.resume(returning: collected)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                    // Release after resuming
                    cancellable?.cancel()
                    cancellable = nil
                }, receiveValue: { value in
                    collected.append(value)
                })
        }
    }
}
