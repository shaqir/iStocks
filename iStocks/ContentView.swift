//
//  ContentView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-07.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        Text("Hello World")
        
    }
}

#Preview {
    ContentView()
}
