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
    let httpBody: Data?

    init(path: String, method: HTTPMethod = .get, queryItems: [URLQueryItem]? = nil, httpBody: Data? = nil) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.httpBody = httpBody
    }

    var url: URL? {
        var components = URLComponents(string: API.baseURL)
        components?.path += path
        components?.queryItems = queryItems
        return components?.url
    }
}

 
