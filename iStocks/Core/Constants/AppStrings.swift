//
//  AppStrings.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-28.
//

import Foundation

enum AppStrings {
    
    enum General {
        static let ok = "OK"
        static let cancel = "Cancel"
        static let loading = "Loading..."
    }
    
    enum Errors {
        static let networkError = "Network connection lost."
        static let serverError = "Server error. Please try again later."
    }
    
    enum Animation {
        static let lottie = "lottie"
    }
    
    enum tabNames{
        static let watchlist = "WatchList"
        static let orders = "Orders"
        static let portfolio = "Portfolio"
        static let bids = "Bids"
        static let settings = "Settings"
    }
    
    enum tabImageNames{
        static let watchlistImage = "house"
        static let ordersImage = "chart.line.uptrend.xyaxis"
        static let portfolioImage = "briefcase"
        static let bidImage = "doc.plaintext"
        static let profileImage = "person"
    }
    
}
