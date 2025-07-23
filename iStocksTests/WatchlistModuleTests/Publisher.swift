//
//  Publisher.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import Foundation
import Combine

//Test-Only Extension for Combine
extension Publisher {
    func asyncValue() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = self
                .sink(receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        continuation.resume(throwing: error)
                    }
                }, receiveValue: { value in
                    continuation.resume(returning: value)
                    cancellable?.cancel()
                })
        }
    }
}
