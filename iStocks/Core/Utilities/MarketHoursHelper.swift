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
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!

        let weekday = calendar.component(.weekday, from: now) // 1 = Sunday ... 7 = Saturday
        let isWeekday = weekday >= 2 && weekday <= 6

        // NYSE hours: 9:30 AM – 4:00 PM Eastern = 570–960 minutes since midnight
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let minutesSinceMidnight = hour * 60 + minute
        let isMarketHours = minutesSinceMidnight >= 570 && minutesSinceMidnight < 960

        return isWeekday && isMarketHours
    }
}
