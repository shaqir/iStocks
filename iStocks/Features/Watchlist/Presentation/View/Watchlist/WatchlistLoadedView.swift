//
//  WatchlistLoadedView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-01.

import SwiftUI

struct WatchlistLoadedView: View {
    @ObservedObject var viewModel: WatchlistViewModel
    var scrollOffset: Binding<CGFloat> = .constant(0)
    
    @State private var isShowingStockPicker = false
    @State private var pausedLiveUpdates: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView("Fetching Stocks…")
            } else if let error = viewModel.errorMessage {
                WatchlistErrorView(error: error) {
                    //viewModel.refresh()
                }
            } else {
                WatchlistScrollContainer(
                    searchText: $viewModel.searchText,
                    isAddButtonVisible: viewModel.selectedStocks.count < AppConstants.maxStocksPerWatchlist,
                    onAddTapped: {
                        pauseLiveUpdates()
                        isShowingStockPicker = true
                    },
                    content: {
                        WatchlistStockListView(viewModel: viewModel)
                    },
                    scrollOffset: scrollOffset
                )
            }
        }
        .onAppear {
            if !pausedLiveUpdates {
                viewModel.observeLiveUpdates()
            }
        }
        .sheet(isPresented: $isShowingStockPicker, onDismiss: {
            resumeLiveUpdates()
        }) {
            let editViewModel = EditWatchlistViewModel(
                watchlist: viewModel.watchlist,
                availableStocks: MockStockData.allStocks
            )
            StockPickerView(viewModel: editViewModel,
                            onSave: viewModel.watchlistDidUpdate)
        }
    }

    // MARK: - Pause/Resume Live Updates

    private func pauseLiveUpdates() {
        pausedLiveUpdates = true
        viewModel.cancelLiveUpdates()
    }

    private func resumeLiveUpdates() {
        pausedLiveUpdates = false
        viewModel.observeLiveUpdates()
    }
}

// MARK: - Stock List

struct WatchlistStockListView: View {
    @ObservedObject var viewModel: WatchlistViewModel

    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(viewModel.filteredStocks.indices, id: \.self) { index in
                let stock = viewModel.filteredStocks[index]
                VStack(spacing: 0) {
                    WatchlistRowView(stock: stock, isAnimated: viewModel.animatedSymbols.contains(stock.symbol))
                }
                .padding(.top, index == 0 ? 4 : 0)
            }
        }
    }
}

// MARK: - Row View

struct WatchlistRowView: View {
    let stock: Stock
    let isAnimated: Bool

    var body: some View {
        WatchlistRow(stock: stock)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
            )
            .scaleEffect(isAnimated ? 1.05 : 1.0)
            .opacity(isAnimated ? 0 : 1)
            .animation(.easeOut(duration: 0.5), value: isAnimated)
            .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Scroll Container

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
                    Section(header:
                        WatchlistStickySearchBar(
                            searchText: searchText,
                            isAddButtonVisible: isAddButtonVisible,
                            onAddTapped: onAddTapped
                        )
                    ) {
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
}

// MARK: - Sticky Search Bar

struct WatchlistStickySearchBar: View {
    @Binding var searchText: String
    var isAddButtonVisible: Bool
    var onAddTapped: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Search stocks", text: $searchText)
                    .font(.system(size: 14))
                    .disableAutocorrection(true)
                    .frame(maxWidth: .infinity)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
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
                    Text("Add Stocks")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                }
                .frame(height: 44)
                .transition(.opacity)
                .animation(.easeInOut, value: isAddButtonVisible)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Scroll Offset Preference

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
