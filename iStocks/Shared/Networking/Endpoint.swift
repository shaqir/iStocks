//
//  Endpoint.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    // Extend as needed
}

struct Endpoint {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]?

    var url: URL? {
        var components = URLComponents(string: "https://api.twelvedata.com")
        components?.path += path
        components?.queryItems = queryItems
        return components?.url
    }
}
