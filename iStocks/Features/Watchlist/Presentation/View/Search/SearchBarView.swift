//
//  SearchBarView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-01.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    var countText: String
    var onFilterTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search & add", text: $searchText)
                .font(.system(size: 14))
                .disableAutocorrection(true)
                 
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            
            Spacer()
            
            Text(countText)
                .foregroundColor(.gray)
                .font(.system(size: 12))
            
            Button(action: onFilterTapped) {
                Image(systemName: "line.horizontal.3.decrease.circle")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}
