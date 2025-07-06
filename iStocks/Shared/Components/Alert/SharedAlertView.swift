//
//  SharedAlertView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-05.
//

import SwiftUI

struct SharedAlertView: View {
    let data: SharedAlertData
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            VStack(spacing: 16) {
                if let icon = data.icon {
                    Image(systemName: icon)
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                }

                Text(data.title)
                    .font(.headline)

                Text(data.message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)

                Button("OK") {
                    onDismiss()
                }
                .padding(.top, 8)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 10)
            .frame(maxWidth: 300)
        }
    }
}
