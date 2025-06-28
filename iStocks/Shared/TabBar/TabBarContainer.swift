//
//  CustomTabBarContainer.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-28.
//

import SwiftUI

struct TabBarContainer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController { MainTabBar() }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context){}
}
