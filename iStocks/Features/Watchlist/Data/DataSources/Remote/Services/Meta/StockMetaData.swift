//
//  StockMetaData.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-09.
//

import Foundation

struct StockMetadata: Codable, Identifiable {
    var id: String { symbol }
    let symbol: String
    let name: String
    let exchange: String
    let currency: String?
    
    static let sectorMap: [String: String] = [
        // Technology
        "AAPL": "Technology",
        "MSFT": "Technology",
        "GOOGL": "Technology",
        "IBM": "Technology",
        "INTC": "Technology",

        // Financials
        "JPM": "Financials",
        "BAC": "Financials",
        "GS": "Financials",
        "C": "Financials",
        "WFC": "Financials",

        // Healthcare
        "JNJ": "Healthcare",
        "PFE": "Healthcare",
        "MRK": "Healthcare",
        "UNH": "Healthcare",
        "LLY": "Healthcare",

        // Energy
        "XOM": "Energy",
        "CVX": "Energy",
        "COP": "Energy",
        "SLB": "Energy",
        "MPC": "Energy",

        // Consumer Staples
        "PG": "Consumer Staples",
        "KO": "Consumer Staples",
        "PEP": "Consumer Staples",
        "WMT": "Consumer Staples",
        "COST": "Consumer Staples",

        // Industrials
        "GE": "Industrials",
        "BA": "Industrials",
        "CAT": "Industrials",
        "MMM": "Industrials",
        "HON": "Industrials",

        // Utilities
        "NEE": "Utilities",
        "DUK": "Utilities",
        "SO": "Utilities",
        "AEP": "Utilities",
        "EXC": "Utilities",

        // Communication Services
        "VZ": "Communication Services",
        "T": "Communication Services",
        "TMUS": "Communication Services",
        "DIS": "Communication Services",
        "CMCSA": "Communication Services",

        // Materials
        "LIN": "Materials",
        "SHW": "Materials",
        "ECL": "Materials",
        "DOW": "Materials",
        "NEM": "Materials"
    ]
}
 
