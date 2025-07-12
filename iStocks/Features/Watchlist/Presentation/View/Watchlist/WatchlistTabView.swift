//
//  WatchlistTabView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//
import Foundation
import Combine
import SwiftUI

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
                    WatchlistTabContent(
                        viewModel: viewModel,
                        viewModelProvider: viewModelProvider,
                        scrollOffsets: $scrollOffsets,
                        watchlistToEdit: $watchlistToEdit
                    )
                }

                if viewModel.isLoading {
                    LoadingOverlay()
                }
            }
            .onAppear {
                viewModelProvider.watchlistDidUpdate
                    .receive(on: DispatchQueue.main)
                    .sink { updated in
                        viewModel.updateWatchlist(id: updated.id, with: updated)
                    }
                    .store(in: &combineCancellables)
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
        }
        .sheet(item: $watchlistToEdit) { watchlist in
            EditWatchlistWrapper(watchlist: watchlist,
                                 didSaveSubject: didSaveSubject,
                                 isNewWatchlist: false)
                .onReceive(didSaveSubject) { updated in
                    viewModel.updateWatchlist(id: updated.id, with: updated)
                    watchlistToEdit = nil
                }
        }
        .sheet(item: $newWatchlist) { newWatchlist in
            EditWatchlistWrapper(
                watchlist: newWatchlist,
                didSaveSubject: didSaveSubject,
                isNewWatchlist: true
            )
            .onReceive(didSaveSubject) { saved in
                viewModel.addWatchlist(id: saved.id, with: saved)
                self.newWatchlist = nil
            }
        }
    }
    }

// MARK: - Subviews

struct LoadingOverlay: View {
    var body: some View {
        Color.black.opacity(0.2).ignoresSafeArea()
        ProgressView("Loading...")
            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 5)
    }
}

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
                    SharedAlertManager.shared.show(WatchlistValidationError.tooManyWatchlists.alert)
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
        }
        .frame(height: 48)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().fill(Color.gray.opacity(0.15)).frame(height: 0.5), alignment: .bottom)
    }
}

struct WatchlistTabContent: View {
    @ObservedObject var viewModel: WatchlistsViewModel
    var viewModelProvider: WatchlistViewModelProvider
    @Binding var scrollOffsets: [UUID: CGFloat]
    @Binding var watchlistToEdit: Watchlist?

    private var selectedTabBinding: Binding<Int> {
        Binding(get: { viewModel.selectedIndex }, set: { viewModel.selectedIndex = $0 })
    }

    var body: some View {
        TabView(selection: selectedTabBinding) {
            ForEach(viewModel.watchlists.indices, id: \..self) { index in
                let watchlist = viewModel.watchlists[index]
                let tabViewModel = viewModelProvider.viewModel(for: watchlist)

                let offsetBinding = Binding<CGFloat>(
                    get: { scrollOffsets[watchlist.id, default: 0] },
                    set: { scrollOffsets[watchlist.id] = $0 }
                )

                WatchlistLoadedView(viewModel: tabViewModel, scrollOffset: offsetBinding)
                    .id(watchlist.id)
                    .tag(index)
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

    var body: some View {
        let viewModel = EditWatchlistViewModel(
            watchlist: watchlist,
            availableStocks: MockStockData.allStocks,
            isNewWatchlist: isNewWatchlist
        )

        EditSingleWatchlistView(viewModel: viewModel, watchlistDidSave: didSaveSubject)
    }
}
