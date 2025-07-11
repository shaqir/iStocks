//
//  Untitled.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-10.
//

import Foundation

enum RepositoryError: LocalizedError {
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "This method is not implemented in the mock repository."
        }
    }
}
