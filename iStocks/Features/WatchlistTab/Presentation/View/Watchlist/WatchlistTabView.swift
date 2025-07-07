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
    
    @State private var isEditingAllWatchlists = false
    @State private var watchlistToEdit: Watchlist?
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
                    HStack(spacing: 8) {
                        // Scrollable Tab Bar
                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.watchlists.indices, id: \.self) { index in
                                        let isSelected = viewModel.selectedIndex == index
                                        
                                        Button(action: {
                                            viewModel.selectedIndex = index
                                            withAnimation(.easeInOut) {
                                                proxy.scrollTo(index, anchor: .center)
                                            }
                                        }) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(viewModel.watchlists[index].name)
                                                    .font(.watchlistTabCaption)
                                                    .foregroundColor(isSelected ? Color.blue : .captionGray)
                                                
                                                ZStack {
                                                    if isSelected {
                                                        Capsule()
                                                            .fill(Color.blue)
                                                            .matchedGeometryEffect(id: "underline", in: underlineNamespace)
                                                            .frame(width: 24, height: 2)
                                                            .offset(x: 0)
                                                        
                                                    } else {
                                                        Color.clear.frame(height: 2)
                                                    }
                                                }
                                            }
                                            .id(index)
                                            .padding(.horizontal, 6) // Add a little side padding
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
                        .layoutPriority(1) //Let ScrollView take all available space first
                        
                        // Add Button
                        Button(action: {
                            if viewModel.watchlists.count >= 20 {
                                SharedAlertManager.shared.show(
                                    SharedAlertData(
                                        title: "Limit Reached",
                                        message: "You can only create up to 20 watchlists.",
                                        icon: "exclamationmark.triangle.fill",
                                        action: nil
                                    )
                                )
                            } else {
                                isPresentingNewWatchlist = true
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .padding(.trailing, 16)
                        }
                        .offset(y: -4) // Slightly float the button above center
                    }
                    .frame(height: 48) // Consistent height for the entire row
                    .background(.ultraThinMaterial) //  Elevated, blurred background
                    .clipShape(Rectangle()) // ensures shadow is tight
                    .shadow(color: Color.black.opacity(0.04), radius: 1.5, x: 0, y: 1)
                    .overlay(
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 0.5),
                        alignment: .bottom
                    )
                    
                    // MARK: - Swipeable Tab Content
                    ZStack {
                        ForEach(viewModel.watchlists.indices, id: \.self) { index in
                            if viewModel.selectedIndex == index {
                                buildTabView(for: index)
                                    .transition(.opacity)
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.15), value: viewModel.selectedIndex)
                }
                .onAppear {
                    viewModel.loadWatchlists()
                }
            }
        }
        .sheet(isPresented: $isEditingAllWatchlists) {
            EditAllWatchlistsView(
                watchlists: $viewModel.watchlists,
                persistenceService: viewModel.persistenceService,
                onSave: {
                    viewModel.saveAllWatchlists()
                }
            )
            .environmentObject(SharedAlertManager.shared)
        }
        
        .sheet(item: $watchlistToEdit) { watchlist in
            EditSingleWatchlistView(
                watchlist: watchlist,
                onSave: { updated in
                    if let index = viewModel.watchlists.firstIndex(where: { $0.id == updated.id }) {
                        viewModel.watchlists[index] = updated
                        viewModel.saveAllWatchlists()
                    }
                    watchlistToEdit = nil
                },
                onDismiss: {
                    watchlistToEdit = nil
                },
                isNewWatchlist: false
            )
            .environmentObject(SharedAlertManager.shared)
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
                }, isNewWatchlist: true
            ).environmentObject(SharedAlertManager.shared)
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
        }
    }
}

