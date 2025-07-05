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

            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search your stocks", text: $viewModel.searchText)
                        .font(.system(size: 14))
                        .disableAutocorrection(true)

                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.searchText = ""
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

                Button(action: {
                    isShowingStockPicker = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.app.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Add Stock")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                    .scaleEffect(isShowingStockPicker ? 0.95 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isShowingStockPicker)
                }

            }
            .padding(.horizontal, 16)
            .padding(.top, 24)

            
            if viewModel.isLoading {
                ProgressView("Fetching Stocks…")
            }
            else if let error = viewModel.errorMessage {
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
        .sheet(isPresented: $isShowingStockPicker) {
            StockPickerView(
                allStocks: MockStockData.allStocks,
                alreadySelectedStocks: viewModel.stocks,
                onSelect: { selected in
                    viewModel.addStock(selected)
                }
            )
        }

    }
}


private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
