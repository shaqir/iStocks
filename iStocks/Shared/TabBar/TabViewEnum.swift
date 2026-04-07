//
//  TabViewEnum.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-28.
//

import Foundation
import SwiftUI

nonisolated enum TabViewEnum: Identifiable, CaseIterable, Hashable {
    case watchlist, orders, portfolio, research, settings

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
        case .research:
            .init(title: AppStrings.TabNames.research,
                  imageName: AppStrings.TabImageNames.researchImage,
                  color: .blue)
        case .settings:
            .init(title: AppStrings.TabNames.settings,
                  imageName: AppStrings.TabImageNames.profileImage,
                  color: .blue)
        }
    }
}
