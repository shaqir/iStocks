//
//  MarketHoursHelper.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-19.
//

import Foundation 

enum MarketHoursHelper {
    
    static func isUSMarketOpen() -> Bool {
        let now = Date()
        let calendar = Calendar(identifier: .gregorian)
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now) // 1 = Sunday ... 7 = Saturday

        let isWeekday = weekday >= 2 && weekday <= 6
        let isMarketHours = hour >= 8 && hour <= 16 // Rough EDT range

        return isWeekday && isMarketHours
    }
}
