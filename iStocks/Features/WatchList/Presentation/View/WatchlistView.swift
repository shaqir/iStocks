//
//  WatchlistView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import SwiftUI
import SwiftData

struct WatchlistView: View {
    //Injects ModelContext from SwiftData
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: WatchlistViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: WatchlistViewModel.previewInstance())
    }
    var body: some View {
        NavigationView {
            VStack {
                
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .padding()
                } else if let error = viewModel.errorMessage {
                    Text("\(error)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List{
                        ForEach(viewModel.groupedStocks.keys.sorted(), id: \.self){ group in
                            Section(header: Text(group).font(.headline)) {
                                ForEach(viewModel.groupedStocks[group] ?? []) { stock in
                                    WatchlistRow(stock: stock)
                                }
                            }
                        }
                    }//List
                    .listStyle(.insetGrouped)
                    .refreshable {
                        viewModel.fetchStocks() // Pull to Refresh
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search by symbol")
            .onAppear {
                viewModel.fetchStocks()
                //viewModel.startAutoRefresh(interval: 10) // Refresh every 10 seconds
            }
            .onDisappear {
                viewModel.stopAutoRefresh()
            }
        }
    }
}
 
#Preview {
    WatchlistView()
}
