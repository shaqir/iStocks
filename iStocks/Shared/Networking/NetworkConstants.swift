//
//  NetworkConstants.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import Foundation

enum API {
    static let baseURL = "https://api.twelvedata.com"
    static let graphQLBaseURL = "https://api.twelvedata.com/graphql"
    static let apiKey_TwelveData = ""
    static let apiKey_finnhub = ""

    static func validateKeys() {
        assert(!apiKey_TwelveData.isEmpty, "TwelveData API key is not configured — set it in NetworkConstants.swift")
        assert(!apiKey_finnhub.isEmpty, "Finnhub API key is not configured — set it in NetworkConstants.swift")
    }
}
