//
//  AppStrings.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-28.
//

import Foundation

nonisolated enum AppStrings {
    
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
    
    enum TabNames {
        static let watchlist = "Watchlist"
        static let orders = "Orders"
        static let portfolio = "Portfolio"
        static let research = "Research"
        static let bids = "Bids"
        static let settings = "Settings"
    }

    enum TabImageNames {
        static let watchlistImage = "house"
        static let ordersImage = "chart.line.uptrend.xyaxis"
        static let portfolioImage = "briefcase"
        static let researchImage = "globe"
        static let bidImage = "doc.plaintext"
        static let profileImage = "person"
    }
    
}
