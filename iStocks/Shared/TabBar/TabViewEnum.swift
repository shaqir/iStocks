//
//  TabViewEnum.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-28.
//

import Foundation
import SwiftUI

enum TabViewEnum: Identifiable, CaseIterable, Hashable {
    case watchlist, orders, portfolio, bids, settings

    var id: Self { self }

    var tabItem: TabItem {
        switch self {
        case .watchlist:
            .init(title: AppStrings.TabNames.watchlist,
                  imageName: AppStrings.TabImageNames.watchlistImage,
                  color: .blue)
        case .orders:
            .init(title: AppStrings.TabNames.orders,
                  imageName: AppStrings.TabImageNames.ordersImage,
                  color: .blue)
        case .portfolio:
            .init(title: AppStrings.TabNames.portfolio,
                  imageName: AppStrings.TabImageNames.portfolioImage,
                  color: .blue)
        case .bids:
            .init(title: AppStrings.TabNames.bids,
                  imageName: AppStrings.TabImageNames.bidImage,
                  color: .blue)
        case .settings:
            .init(title: AppStrings.TabNames.settings,
                  imageName: AppStrings.TabImageNames.profileImage,
                  color: .blue)
        }
    }
}
