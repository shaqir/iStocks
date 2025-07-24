//
//  Publisher+Extensions.swift
//  iStocksIntegrationTests
//
//  Created by Sakir Saiyed on 2025-07-23.
//

import Foundation
internal import Combine

extension Publisher {
    func asyncValues() async throws -> [Output] {
        try await withCheckedThrowingContinuation { continuation in
            var collected: [Output] = []
            let cancellable = self
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.resume(returning: collected)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }, receiveValue: { value in
                    collected.append(value)
                })

            // Cancellation cleanup optional
            Task {
                try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                _ = cancellable
            }
        }
    }
}
