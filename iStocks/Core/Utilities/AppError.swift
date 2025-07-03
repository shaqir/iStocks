//
//  AppError.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import Foundation

enum AppError: LocalizedError {
    case network(NetworkError)
    case api(message: String)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .network(let error): return error.localizedDescription
        case .api(let message): return message
        case .unknown(let error): return error.localizedDescription
        }
    }
}
