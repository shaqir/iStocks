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
    private let viewModelProvider = WatchlistViewModelProvider()

    @State private var scrollOffsets: [UUID: CGFloat] = [:]
    @State private var isEditingAllWatchlists = false
    @State private var watchlistToEdit: Watchlist?
    @State private var isPresentingNewWatchlist = false

    @State private var combineCancellables = Set<AnyCancellable>()

    private var selectedTabBinding: Binding<Int> {
        Binding(
            get: { viewModel.selectedIndex },
            set: { viewModel.selectedIndex = $0 }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                VStack(spacing: 0) {
                    tabBar()
                    tabContentView()
                }
            }
            .onAppear {
                viewModel.loadWatchlists()
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
            let didSave = PassthroughSubject<Watchlist, Never>()
            EditSingleWatchlistView(
                watchlist: watchlist,
                isNewWatchlist: false,
                watchlistDidSave: didSave
            )
            .onReceive(didSave) { updated in
                viewModel.updateWatchlist(id: updated.id, with: updated)
                viewModel.saveAllWatchlists()
                watchlistToEdit = nil
            }
        }
        .sheet(isPresented: $isPresentingNewWatchlist) {
            let newWatchlist = Watchlist(id: UUID(), name: "", stocks: [])
            let didSave = PassthroughSubject<Watchlist, Never>()

            EditSingleWatchlistView(
                watchlist: newWatchlist,
                isNewWatchlist: true,
                watchlistDidSave: didSave
            )
            .onReceive(didSave) { saved in
                viewModel.watchlists.append(saved)
                viewModel.saveAllWatchlists()
                isPresentingNewWatchlist = false
            }
        }
    }

    // MARK: - Tab Bar
    private func tabBar() -> some View {
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
                                            .frame(width: 20, height: 2, alignment: .leading) // approx. 3–4 characters wide
                                    }
                                }
                                .padding(.horizontal, 8)
                                .id(index)
                            }
                            .buttonStyle(.plain)
                            .onLongPressGesture {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                isEditingAllWatchlists = true
                            }
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
                if viewModel.watchlists.count >= 20 {
                    SharedAlertManager.shared.show(
                        SharedAlertData(title: "Limit Reached",
                                        message: "Max 20 watchlists",
                                        icon: "exclamationmark.triangle",
                                        action: nil)
                    )
                } else {
                    isPresentingNewWatchlist = true
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

    // MARK: - Tab Content
    private func tabContentView() -> some View {
        TabView(selection: selectedTabBinding) {
            ForEach(viewModel.watchlists.indices, id: \..self) { index in
                let watchlist = viewModel.watchlists[index]
                let tabViewModel = viewModelProvider.viewModel(for: watchlist)

                let offsetBinding = Binding<CGFloat>(
                    get: { scrollOffsets[watchlist.id, default: 0] },
                    set: { scrollOffsets[watchlist.id] = $0 }
                )

                WatchlistLoadedView(viewModel: tabViewModel, scrollOffset: offsetBinding)
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
