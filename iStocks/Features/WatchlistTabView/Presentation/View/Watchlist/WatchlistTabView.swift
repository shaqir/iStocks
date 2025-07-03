//
//  WatchlistTabView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import SwiftUI

struct WatchlistTabView: View {
    
    @ObservedObject var viewModel: WatchlistsViewModel
    @Namespace private var underlineNamespace
    private let viewModelProvider = WatchlistViewModelProvider()
    @State private var scrollOffsets: [UUID: CGFloat] = [:]
    
    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()//Color(hex: "e9edee")
            
            VStack(spacing: 0) {
                // MARK: - Tab Bar
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(viewModel.watchlists.indices, id: \.self) { index in
                                let isSelected = viewModel.selectedIndex == index
                                
                                Button(action: {
                                    withAnimation(.easeInOut) {
                                        viewModel.selectedIndex = index
                                        proxy.scrollTo(index, anchor: .center)
                                    }
                                }) {
                                    VStack(spacing: 2) {
                                        Text(viewModel.watchlists[index].name)
                                            .font(.watchlistTabCaption)
                                            .foregroundColor(isSelected ? Color.blue : .captionGray)
                                        ZStack {
                                            if isSelected {
                                                Capsule()
                                                    .fill(Color.blue)
                                                    .matchedGeometryEffect(id: "underline", in: underlineNamespace)
                                                    .frame(height: 2)
                                            } else {
                                                Color.clear.frame(height: 2)
                                            }
                                        }
                                    }
                                    .id(index)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    }
                    .onChange(of: viewModel.selectedIndex) {
                        withAnimation {
                            proxy.scrollTo(viewModel.selectedIndex, anchor: .center)
                        }
                    }
                }
                
                Divider().background(Color.gray.opacity(0.2))
                
                // MARK: - Swipeable Tab Content (Lazy Loading)
                TabView(selection: $viewModel.selectedIndex) {
                    ForEach(viewModel.watchlists.indices, id: \.self) { index in
                        buildTabView(for: index).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .onAppear {
                viewModel.loadWatchlists()
            }
        }
    }
    
    // MARK: - Helper
    @ViewBuilder
    private func buildTabView(for index: Int) -> some View {
        let watchlist = viewModel.watchlists[index]
        
        /*
         That viewModelProvider ensures:
         - You reuse the same WatchlistViewModel instance per watchlist tab.
         - No re-creation of view models on every render or swipe.
         - This is efficient and avoids recomputation.
         */
        let tabViewModel = viewModelProvider.viewModel(for: watchlist)
        
        let offsetBinding = Binding<CGFloat>(
            get: { scrollOffsets[watchlist.id, default: 0] },
            set: { scrollOffsets[watchlist.id] = $0 }
        )
        
        WatchlistLoadedView(
            viewModel: tabViewModel,
            scrollOffset: offsetBinding
        )
    }
}
