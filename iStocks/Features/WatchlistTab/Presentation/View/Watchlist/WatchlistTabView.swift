//
//  WatchlistTabView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import SwiftUI

import SwiftUI

struct WatchlistTabView: View {
    
    @ObservedObject var viewModel: WatchlistsViewModel
    @Namespace private var underlineNamespace
    private let viewModelProvider = WatchlistViewModelProvider()
    @State private var scrollOffsets: [UUID: CGFloat] = [:]
    
    @State private var isEditingAllWatchlists = false
    @State private var watchlistToEdit: Watchlist?
    @State private var isPresentingEdit = false
    @State private var isPresentingNewWatchlist = false
    
    init(viewModel: WatchlistsViewModel) {
        self.viewModel = viewModel

        // Set up persistence callback when a stock is added
        viewModelProvider.onUpdate = { updatedWatchlist in
            viewModel.updateWatchlist(id: updatedWatchlist.id, with: updatedWatchlist)
        }
    }

    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // MARK: - Tab Bar with trailing + button
                    HStack(spacing: 0) {
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
                                            .onLongPressGesture {
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                isEditingAllWatchlists = true
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.leading, 16)
                                .padding(.vertical, 12)
                            }
                            .onChange(of: viewModel.selectedIndex) {
                                withAnimation {
                                    proxy.scrollTo(viewModel.selectedIndex, anchor: .center)
                                }
                            }
                        }
                        
                        // ➕ Button always visible and aligned
                        Button(action: {
                            isPresentingNewWatchlist = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 12)
                        }
                    }
                    
                    Divider().background(Color.gray.opacity(0.2))
                    
                    // MARK: - Swipeable Tab Content
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
        .sheet(isPresented: $isEditingAllWatchlists) {
            EditAllWatchlistsView(
                watchlists: $viewModel.watchlists,
                onSave: {
                    viewModel.saveAllWatchlists()
                }
            )
        }
        .sheet(isPresented: $isPresentingEdit) {
            if let watchlist = watchlistToEdit {
                EditSingleWatchlistView(
                    watchlist: watchlist,
                    onSave: { updated in
                        if let index = viewModel.watchlists.firstIndex(where: { $0.id == updated.id }) {
                            viewModel.watchlists[index] = updated
                            viewModel.saveAllWatchlists()
                        }
                        isPresentingEdit = false
                    },
                    onDismiss: {
                        isPresentingEdit = false
                    }
                )
            }
        }
        .sheet(isPresented: $isPresentingNewWatchlist) {
            EditSingleWatchlistView(
                watchlist: Watchlist(id: UUID(), name: "", stocks: []),
                onSave: { newWatchlist in
                    viewModel.watchlists.append(newWatchlist)
                    viewModel.saveAllWatchlists()
                    isPresentingNewWatchlist = false
                },
                onDismiss: {
                    isPresentingNewWatchlist = false
                }
            )
        }
    }
    
    // MARK: - Helper
    @ViewBuilder
    private func buildTabView(for index: Int) -> some View {
        let watchlist = viewModel.watchlists[index]
        let tabViewModel = viewModelProvider.viewModel(for: watchlist)
        
        let offsetBinding = Binding<CGFloat>(
            get: { scrollOffsets[watchlist.id, default: 0] },
            set: { scrollOffsets[watchlist.id] = $0 }
        )
        
        WatchlistLoadedView(
            viewModel: tabViewModel,
            scrollOffset: offsetBinding
        )
        .onLongPressGesture {
            self.watchlistToEdit = watchlist
            self.isPresentingEdit = true
        }
    }
}
