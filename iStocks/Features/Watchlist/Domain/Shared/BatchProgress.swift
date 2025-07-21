//
//  BatchProgress.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-20.
//
import Foundation
struct BatchProgress {
    let current: Int
    let total: Int
    let retryCount: Int
    let success: Bool

    var isComplete: Bool {
        current >= total
    }
}
