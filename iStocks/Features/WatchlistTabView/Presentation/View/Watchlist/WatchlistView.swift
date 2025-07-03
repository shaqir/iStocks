//
//  WatchlistView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import SwiftUI
import Combine

struct WatchlistView: View {
    
    let viewModel: WatchlistViewModel

    var body: some View {
        NavigationStack {
            WatchlistLoadedView(viewModel: viewModel)
        }
    }
}
