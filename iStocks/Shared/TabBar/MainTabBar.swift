//
//  HostingTabBarController.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-28.
//

import SwiftUI

class MainTabBar: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let tabs = TabViewEnum.allCases.map { tab in
            let controller = UIHostingController(rootView: tab)
            controller.tabBarItem = UITabBarItem(
                title: tab.tabItem.title,
                image: UIImage(systemName: tab.tabItem.imageName),
                selectedImage: nil
            )
            return controller
        }
        viewControllers = tabs
        setupTabBarAppearance()
    }
    
    private func setupTabBarAppearance() {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            
            // Unselected item appearance
            let normalAttributes: [NSAttributedString.Key: Any] = [
                .font: AppFont.UIKit.regular(size: AppSizes.Tab.labelSize),
                .foregroundColor: UIColor(.textColor)
            ]
            
            // Selected item appearance
            let selectedAttributes: [NSAttributedString.Key: Any] = [
                .font: AppFont.UIKit.regular(size: AppSizes.Tab.labelSize),
                .foregroundColor: UIColor(.primary)
            ]
            
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes

            // Optional: icon tint color (for iOS 15+)
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(.textColor)
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(.primary)
            
            // Apply appearance
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
            
        }
}
