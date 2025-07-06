//
//  WatchlistLoadedView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-01.

import SwiftUI

struct WatchlistLoadedView: View {
    
    @ObservedObject var viewModel: WatchlistViewModel
    var scrollOffset: Binding<CGFloat> = .constant(0) // Optional fallback for standalone use
    
    @State private var isShowingStockPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView("Fetching Stocks…")
            }
            else if let error = viewModel.errorMessage {
                WatchlistErrorView(error: error) {
                    //viewModel.refresh()
                }
            } else {
                WatchlistScrollContainer(
                    searchText: $viewModel.searchText,
                    isAddButtonVisible: viewModel.stocks.count < 20,
                    onAddTapped: {
                        isShowingStockPicker = true
                    },
                    content: {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.filteredStocks.indices, id: \.self) { index in
                                let stock = viewModel.filteredStocks[index]
                                VStack(spacing: 0) {
                                    WatchlistRow(stock: stock)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.white)
                                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
                                        )
                                        .transition(.opacity.combined(with: .scale))
                                }
                                .padding(.top, index == 0 ? 4 : 0)
                            }
                        }
                    },
                    scrollOffset: scrollOffset
                )
            }
        }
        .sheet(isPresented: $isShowingStockPicker) {
            StockPickerView(
                allStocks: MockStockData.allStocks,
                alreadySelectedStocks: viewModel.stocks,
                onSelect: { selected in
                    viewModel.addStock(selected)
                }
            )
            .environmentObject(SharedAlertManager.shared)
        }
    }
}


private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct WatchlistScrollContainer<Content: View>: View {
    let searchText: Binding<String>
    let isAddButtonVisible: Bool
    let onAddTapped: () -> Void
    let content: () -> Content
    let scrollOffset: Binding<CGFloat>

    var body: some View {
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

                LazyVStack(pinnedViews: [.sectionHeaders]) {
                    // Sticky search bar
                    Section(header: stickySearchBar) {
                        content()
                            .padding(.horizontal, 16)
                            .padding(.bottom, 48) // space for TabBar
                    }
                }
                .padding(.top, 8)
            }
            .coordinateSpace(name: "scrollView")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset.wrappedValue = value
            }
            .ignoresSafeArea(.keyboard)
        }
    }

    private var stickySearchBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Search stocks", text: searchText)
                    .font(.system(size: 14))
                    .disableAutocorrection(true)
                    .frame(maxWidth: .infinity)

                if !searchText.wrappedValue.isEmpty {
                    Button(action: {
                        searchText.wrappedValue = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            )

            if isAddButtonVisible {
                Button(action: onAddTapped) {
                    HStack(spacing: 6) {
                        Text("Add Stocks")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                }
                .frame(height: 44)
                .transition(.opacity)
                .animation(.easeInOut, value: isAddButtonVisible)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial) // So it looks good while scrolling
    }
}
