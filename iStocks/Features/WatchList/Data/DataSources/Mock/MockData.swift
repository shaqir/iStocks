//
//  MockStocks.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import Foundation

struct MockData {
    static let sampleStocks: [Stock] = [
        Stock(symbol: "HDFC BANK",
              ltp: 189.32,
              change: -0.63,
              percentChange: -0.33,
              invested: 100000,
              currentValue: 105000, groupName: "NIFTY 50"),
        Stock(symbol: "Reliance",
              ltp: 680.00,
              change: 12.50,
              percentChange: 1.87,
              invested: 50000,
              currentValue: 52500, groupName: "NIFTY 50"),
        Stock(symbol: "Infosys",
              ltp: 312.90,
              change: 2.10,
              percentChange: 0.67,
              invested: 70000,
              currentValue: 71000, groupName: "My WatchList"),
        Stock(symbol: "Tata Elxsi",
              ltp: 112.90,
              change: 2.10,
              percentChange: 0.67,
              invested: 40000,
              currentValue: 61000, groupName: "F&O")
    ]
}


