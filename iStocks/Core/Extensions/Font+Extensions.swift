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
    
    static func heading(_ size: CGFloat) -> Font {
        .custom("Inter28pt-SemiBold", size: size)
    }

    static func body(_ size: CGFloat) -> Font {
        .custom("Inter28pt-Regular", size: size)
    }

    static func value(_ size: CGFloat) -> Font {
        .custom("Inter28pt-Bold", size: size)
    }
}

 
extension Font {
    static let stockSymbol     = Font.system(size: 17, weight: .semibold)
    static let metricLabel     = Font.system(size: 13, weight: .regular)
    static let investedLabel   = Font.system(size: 13, weight: .medium)
    static let pnlPercentage   = Font.system(size: 14, weight: .semibold)
    static let tabLabel        = Font.system(size: 12, weight: .medium)
    static let stockPnlValue   = Font.system(size: 15, weight: .bold)
    static let stockPercentage = Font.system(size: 14, weight: .semibold)
    static let stockCaption    = Font.system(size: 13, weight: .regular)
    static let watchlistTabCaption    = Font.system(size: 16, weight: .regular)
}
