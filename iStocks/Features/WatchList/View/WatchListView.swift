//
//  WatchListView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-28.
//

import SwiftUI

struct WatchListView: View {
    @State private var searchText = ""
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search and Add Stocks", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 10)
                 Spacer()
            }
            .padding()
            
        }
    }
}


#Preview {
    WatchListView()
}
