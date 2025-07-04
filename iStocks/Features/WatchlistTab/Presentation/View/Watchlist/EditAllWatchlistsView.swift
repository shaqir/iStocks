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
                ForEach($watchlists) { $watchlist in
                    HStack {
                        TextField("Watchlist name", text: $watchlist.name)
                            .font(.system(size: 16))
                            .textFieldStyle(.roundedBorder)
                        
                        Spacer()
                        
                        Button(role: .destructive) {
                            withAnimation {
                                watchlists.removeAll { $0.id == watchlist.id }
                            }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
                .onMove(perform: moveWatchlists)
            }
            .environment(\.editMode, $editMode)
            .navigationTitle("Edit Watchlists")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") {
                    onSave()
                    dismiss()
                },
                trailing: Button(action: addNewWatchlist) {
                    Image(systemName: "plus")
                }
            )
            
        }
    }
    
    private func addNewWatchlist() {
        let newWatchlist = Watchlist(name: "New Watchlist \(watchlists.count + 1)", stocks: [])
        watchlists.append(newWatchlist)
    }
    
    private func moveWatchlists(from source: IndexSet, to destination: Int) {
        watchlists.move(fromOffsets: source, toOffset: destination)
    }
}
