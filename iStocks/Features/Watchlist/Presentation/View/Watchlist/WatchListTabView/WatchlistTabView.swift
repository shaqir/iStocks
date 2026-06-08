//
//  WatchlistTabView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import SwiftUI
import Combine

struct WatchlistTabView: View {
    
    @ObservedObject var viewModel: WatchlistsViewModel
    @Namespace private var underlineNamespace
    let viewModelProvider: WatchlistViewModelProvider
    
    @State private var scrollOffsets: [UUID: CGFloat] = [:]
    @State private var isEditingAllWatchlists = false
    @State private var didSaveSubject = PassthroughSubject<Watchlist, Never>()
    @State private var combineCancellables = Set<AnyCancellable>()
    @State private var watchlistToEdit: Watchlist? = nil
    @State private var newWatchlist: Watchlist? = nil
    
    @State private var refreshCancellable: AnyCancellable?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    WatchlistTabBar(
                        viewModel: viewModel,
                        underlineNamespace: underlineNamespace,
                        isEditingAllWatchlists: $isEditingAllWatchlists,
                        newWatchlist: $newWatchlist
                    )
                    
                    if let progress = viewModel.currentBatchProgress, !progress.isComplete {
                        BatchProgressView(
                            current: progress.current,
                            total: progress.total,
                            retryCount: progress.retryCount,
                            success: progress.success,
                            isComplete: progress.isComplete
                        )
                    }
                    
                    WatchlistTabContent(
                        viewModel: viewModel,
                        viewModelProvider: viewModelProvider,
                        scrollOffsets: $scrollOffsets,
                        watchlistToEdit: $watchlistToEdit
                    )
                }
                
                // Global loading spinner based on WatchlistsViewModel
                if viewModel.isLoading {
                    LoadingOverlay()
                        .transition(.opacity)
                }
            }//Zstack
            .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
             
            .onAppear {
                viewModelProvider.watchlistDidUpdate
                    .receive(on: DispatchQueue.main)
                    .sink { updated in
                        viewModel.updateWatchlist(updated)
                    }
                    .store(in: &combineCancellables)
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
        .sheet(item: $watchlistToEdit) { watchlist in
            EditWatchlistWrapper(watchlist: watchlist,
                                 didSaveSubject: didSaveSubject,
                                 isNewWatchlist: false, availableStocks: viewModel.allFetchedStocks)
            .onReceive(didSaveSubject) { updated in
                viewModel.updateWatchlist(updated)
                watchlistToEdit = nil
            }
        }
        .sheet(item: $newWatchlist) { newWatchlist in
            EditWatchlistWrapper(
                watchlist: newWatchlist,
                didSaveSubject: didSaveSubject,
                isNewWatchlist: true,
                availableStocks: viewModel.allFetchedStocks
            )
            .onReceive(didSaveSubject) { saved in
                viewModel.addWatchlist(saved)
            }
        }
    }
     
}

// MARK: - Subviews

struct WatchlistTabBar: View {
    @ObservedObject var viewModel: WatchlistsViewModel
    var underlineNamespace: Namespace.ID
    @Binding var isEditingAllWatchlists: Bool
    @Binding var newWatchlist: Watchlist?
    
    var body: some View {
        HStack(spacing: 8) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.watchlists.indices, id: \..self) { index in
                            let isSelected = viewModel.selectedIndex == index
                            Button {
                                withAnimation {
                                    viewModel.selectedIndex = index
                                    proxy.scrollTo(index, anchor: .center)
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.watchlists[index].name)
                                        .font(.watchlistTabCaption)
                                        .foregroundColor(isSelected ? .blue : .captionGray)
                                    
                                    if isSelected {
                                        Capsule()
                                            .fill(Color.blue)
                                            .matchedGeometryEffect(id: "underline", in: underlineNamespace)
                                            .frame(width: 20, height: 2, alignment: .leading)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .id(index)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(viewModel.watchlists[index].name) watchlist, tab \(index + 1) of \(viewModel.watchlists.count)")
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                            .accessibilityHint("Switches to this watchlist. Use actions menu to edit all watchlists")
                            .accessibilityAction(named: "Edit watchlists") {
                                isEditingAllWatchlists = true
                            }
                            .simultaneousGesture(
                                LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    isEditingAllWatchlists = true
                                }
                            )
                        }
                    }
                    .padding(.leading, 16)
                }
                .onChange(of: viewModel.selectedIndex) { _, newIndex in
                    withAnimation {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
            Button {
                if viewModel.watchlists.count >= AppConstants.maxWatchlists {
                    SharedAlertManager.shared.show(WatchlistValidationError.limitReached.alert)
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    newWatchlist = Watchlist.empty()
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .padding(.trailing, 16)
            }
            .accessibilityLabel("Add new watchlist")
            .accessibilityHint("Creates a new watchlist tab")
            .accessibilityIdentifier(AccessibilityID.Watchlist.addWatchlistButton)
        }
        .frame(height: 48)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().fill(Color.gray.opacity(0.15)).frame(height: 0.5), alignment: .bottom)
        .accessibilityIdentifier(AccessibilityID.Watchlist.tabBar)
    }
}

struct WatchlistTabContent: View {
    @ObservedObject var viewModel: WatchlistsViewModel
    var viewModelProvider: WatchlistViewModelProvider
    @Binding var scrollOffsets: [UUID: CGFloat]
    @Binding var watchlistToEdit: Watchlist?
    
    @State private var cancellables = Set<AnyCancellable>()

    private var selectedTabBinding: Binding<Int> {
        Binding(get: { viewModel.selectedIndex }, set: { viewModel.selectedIndex = $0 })
    }
    
    var body: some View {
        TabView(selection: selectedTabBinding) {
            ForEach(Array(viewModel.watchlists.enumerated()), id: \.element.id) { index, watchlist in

                // Use the *caching* accessor. `makeWatchlistViewModel` overwrites the cache
                // on every `body` evaluation (and SwiftUI calls `body` often), which builds a
                // fresh ViewModel + re-subscribes Combine pipelines each pass, dropping the
                // child VM's local state. `viewModel(for:)` reuses the cached instance.
                let tabViewModel = viewModelProvider.viewModel(for: watchlist)

                let offsetBinding = Binding<CGFloat>(
                    get: { scrollOffsets[watchlist.id, default: 0] },
                    set: { scrollOffsets[watchlist.id] = $0 }
                )
                //Represents each watchlist tab
                WatchlistLoadedView(viewModel: tabViewModel, scrollOffset: offsetBinding)
                    .id(watchlist.id)
                    .tag(index)
                    .accessibilityAction(named: "Edit this watchlist") {
                        self.watchlistToEdit = watchlist
                    }
                    .onLongPressGesture {
                        self.watchlistToEdit = watchlist
                    }
                     
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.15), value: viewModel.selectedIndex)
        
    }
    
     
    
}

struct EditWatchlistWrapper: View {
    let watchlist: Watchlist
    let didSaveSubject: PassthroughSubject<Watchlist, Never>
    let isNewWatchlist: Bool
    let availableStocks: [Stock]
    
    var body: some View {
        let viewModel = EditWatchlistViewModel(
            watchlist: watchlist,
            availableStocks: availableStocks,
            isNewWatchlist: isNewWatchlist
        )
        
        EditSingleWatchlistView(viewModel: viewModel, watchlistDidSave: didSaveSubject)
    }
}


