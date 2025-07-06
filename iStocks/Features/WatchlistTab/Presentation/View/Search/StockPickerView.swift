//
//  StockPickerView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-04.
//

import SwiftUI

struct StockPickerView: View {
    
    var allStocks: [Stock]
    let alreadySelectedStocks: [Stock]
    let onSelect: (Stock) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    
    var filteredStocks: [Stock] {
        guard !searchText.isEmpty else {
            return allStocks
        }
        
        let lowercasedSearchText = searchText.lowercased()
        
        return allStocks
            .filter { stock in
                !alreadySelectedStocks.contains(where: { $0.symbol == stock.symbol })
            }
            .filter {
                $0.symbol.lowercased().contains(lowercasedSearchText) ||
                $0.name.lowercased().contains(lowercasedSearchText)
            }

    }
    
    var body: some View {
        NavigationStack {
            List(filteredStocks) { stock in
                Button(action: {
                    onSelect(stock)
                    dismiss()
                }) {
                    HStack {
                        Text(stock.symbol)
                            .font(.headline)
                        Spacer()
                        Text(stock.name)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Add Stock")
            .searchable(text: $searchText, prompt: "Search stocks")
        }
    }
}
