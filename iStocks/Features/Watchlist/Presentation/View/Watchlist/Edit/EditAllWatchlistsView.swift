//
//  EditWatchlistsView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-03.
//
import SwiftUI

struct EditAllWatchlistsView: View {
    @Binding var watchlists: [Watchlist]
    @Environment(\.dismiss) private var dismiss
    @State private var editMode: EditMode = .active
    var onSave: () -> Void
    
    // Injected : SwiftData
    let persistenceService: WatchlistPersistenceService
    
    init(
            watchlists: Binding<[Watchlist]>,
            persistenceService: WatchlistPersistenceService,
            onSave: @escaping () -> Void
        ) {
            self._watchlists = watchlists
            self.persistenceService = persistenceService
            self.onSave = onSave
        }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(watchlists) { watchlist in
                    HStack {
                        TextField("Watchlist name", text: editName(for: watchlist))
                            .submitLabel(.done)
                            .accessibilityLabel("Watchlist name")
                            .font(.body)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)

                        Spacer()

                        Button(role: .destructive) {
                            withAnimation {
                                remove(watchlist)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 6)
                }
                .onMove(perform: moveWatchlist)
            }
            .environment(\.editMode, $editMode)
            .listStyle(.insetGrouped)
            .navigationTitle("Edit Watchlists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        let trimmedNames = watchlists.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
                        if trimmedNames.contains(where: { $0.isEmpty }) {
                            SharedAlertManager.shared.show(
                                WatchlistValidationError.emptyName.alert
                            )
                            return
                        }
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func addNewWatchlist() {
        guard watchlists.count < AppConstants.maxWatchlists else {
            SharedAlertManager.shared.show(WatchlistValidationError.tooManyWatchlists.alert)
            return
        }
        let newWatchlist = Watchlist.empty()
        watchlists.append(newWatchlist)
    }

    private func editName(for watchlist: Watchlist) -> Binding<String> {
        guard let index = watchlists.firstIndex(of: watchlist) else {
            return .constant("")
        }
        return $watchlists[index].name
    }
    
    private func remove(_ watchlist: Watchlist) {
        if let index = watchlists.firstIndex(of: watchlist) {
            watchlists.remove(at: index)
        }
    }
    
    private func moveWatchlist(from source: IndexSet, to destination: Int) {
        watchlists.move(fromOffsets: source, toOffset: destination)
    }
    
}
