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

    var body: some View {
        NavigationStack {
            List {
                ForEach(watchlists) { watchlist in
                    HStack {
                        TextField("Watchlist name", text: binding(for: watchlist))
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
                .onMove(perform: moveWatchlists)
            }
            .environment(\.editMode, $editMode)
            .listStyle(.insetGrouped)
            .navigationTitle("Edit Watchlists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onSave()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        addNewWatchlist()
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func addNewWatchlist() {
        let newWatchlist = Watchlist(name: "New Watchlist", stocks: [])
        watchlists.append(newWatchlist)
    }

    private func remove(_ watchlist: Watchlist) {
        if let index = watchlists.firstIndex(of: watchlist) {
            watchlists.remove(at: index)
        }
    }

    private func moveWatchlists(from source: IndexSet, to destination: Int) {
        watchlists.move(fromOffsets: source, toOffset: destination)
    }

    private func binding(for watchlist: Watchlist) -> Binding<String> {
        guard let index = watchlists.firstIndex(of: watchlist) else {
            return .constant("")
        }
        return $watchlists[index].name
    }
}
