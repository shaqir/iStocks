//
//  TabViewEnum.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-28.
//

import Foundation
import SwiftUI

enum TabViewEnum: Identifiable, CaseIterable, View, Hashable {
    
    case watchlist, orders, portfolio, bids, settings
    
    var id:  Self { self }
    
    var tabItem: TabItem {
        switch self {
        case .watchlist:
                .init(title: AppStrings.tabNames.watchlist,
                      imageName: AppStrings.tabImageNames.watchlistImage,
                      color: .blue)
        case .orders:
                .init(title: AppStrings.tabNames.orders,
                      imageName: AppStrings.tabImageNames.ordersImage,
                      color: .blue)
        case .portfolio:
                .init(title: AppStrings.tabNames.portfolio,
                      imageName: AppStrings.tabImageNames.portfolioImage,
                      color: .blue)
        case .bids:
                .init(title: AppStrings.tabNames.bids,
                      imageName: AppStrings.tabImageNames.bidImage,
                      color: .blue)
        case .settings:
                .init(title: AppStrings.tabNames.settings,
                      imageName: AppStrings.tabImageNames.profileImage,
                      color: .blue)
        }
    }
    
    var body: some View {
        switch self {
        case .watchlist: WatchlistView()
        case .orders: OrderView()
        case .portfolio: PortfolioView()
        case .bids: BidsView()
        case .settings: SettingsView()
        }
    }
}
