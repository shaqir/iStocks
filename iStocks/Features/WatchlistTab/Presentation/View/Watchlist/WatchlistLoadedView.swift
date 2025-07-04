//
//  WatchlistLoadedView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-01.

import SwiftUI

struct WatchlistLoadedView: View {

    @ObservedObject var viewModel: WatchlistViewModel
    var scrollOffset: Binding<CGFloat> = .constant(0) // Optional fallback for standalone use

    var body: some View {
        VStack(spacing: 0) {
            SearchBarView(
                searchText: $viewModel.searchText,
                countText: "\(viewModel.filteredStocks.count)/\(viewModel.stocks.count)",
                onFilterTapped: {
                    // Add filter action if needed
                }
            )
            .padding(.horizontal, 16)
            .padding(.top, 24)

            if viewModel.isLoading {
                ProgressView("Fetching Stocks…")
            } else if let error = viewModel.errorMessage {
                WatchlistErrorView(error: error) {
                    //viewModel.refresh()
                }
            } else {
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        GeometryReader { geo in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: -geo.frame(in: .named("scrollView")).origin.y
                                )
                        }
                        .frame(height: 0)

                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.filteredStocks.indices, id: \ .self) { index in
                                let stock = viewModel.filteredStocks[index]
                                VStack(spacing: 0) {
                                    WatchlistRow(stock: stock)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.white)
                                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
                                        )
                                        .transition(.opacity.combined(with: .scale))

                                    if index < viewModel.filteredStocks.count - 1 {
                                        Divider()
                                            .background(Color.gray.opacity(0.3))
                                    }
                                }
                                .padding(.top, index == 0 ? 8 : 0)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 0)
                    }
                    .coordinateSpace(name: "scrollView")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        scrollOffset.wrappedValue = value
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            scrollProxy.scrollTo(0, anchor: UnitPoint(x: 0.5, y: scrollOffset.wrappedValue))
                        }
                    }
                }
            }
        }
    }
}


private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
