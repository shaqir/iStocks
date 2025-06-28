//
//  Font+Extensions.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-28.
//

import SwiftUI

extension UIFont {
    static func interRegular(_ size: CGFloat) -> UIFont {
        UIFont(name: "Inter28pt-Regular", size: size)!
    }

    static func interBold(_ size: CGFloat) -> UIFont {
        UIFont(name: "Inter28pt-Bold", size: size)!
    }
}

extension Font {
    static func interRegular(_ size: CGFloat) -> Font {
        .custom("Inter28pt-Regular", size: size)
    }

    static func interBold(_ size: CGFloat) -> Font {
        .custom("Inter28pt-Bold", size: size)
    }
}
