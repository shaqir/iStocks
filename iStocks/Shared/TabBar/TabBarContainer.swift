//
//  CustomTabBarContainer.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-28.
//

import SwiftUI

struct TabBarContainer: View {
    @State private var selectedTab: TabViewEnum = .watchlist

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                TabRouterView(tab: selectedTab)
                Spacer(minLength: 0)
            }

            CustomTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 12)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}
