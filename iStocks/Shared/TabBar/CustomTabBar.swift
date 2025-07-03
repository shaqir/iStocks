//
//  CustomTabBar.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-01.
//

import SwiftUI 
import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: TabViewEnum

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.captionGray.opacity(0.25))

            HStack {
                ForEach(TabViewEnum.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.tabItem.imageName)
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(selectedTab == tab ? .blue : .captionGray)

                            Text(tab.tabItem.title)
                                .font(.footnote)
                                .fontWeight(selectedTab == tab ? .semibold : .regular)
                                .foregroundColor(selectedTab == tab ? .blue : .captionGray)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 6)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
            .background(
                Color.white
                    .edgesIgnoringSafeArea(.bottom) // Covers home indicator area
            )
        }
        .background(Color.white)
    }
}
