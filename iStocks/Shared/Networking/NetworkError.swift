//
//  NetworkError.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case noData
}
