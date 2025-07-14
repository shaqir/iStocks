//
//  LoadingOverlay.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-12.
//
import SwiftUI

struct LoadingOverlay: View {
    var message: String = "Fetching stocks…"

    var body: some View {
        ZStack {
            // Dimmed, blurred backdrop
            VisualEffectBlur(blurStyle: .systemMaterial)
                .ignoresSafeArea()
                .opacity(0.7)

            // Centered loading card
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 4)
                        .frame(width: 48, height: 48)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.2)
                }

                Text(message)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
            )
            .padding(.horizontal, 40)
        }
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
