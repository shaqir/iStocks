//
//  AppFonts.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-28.
//

import UIKit
import SwiftUI

enum AppFont {
    // MARK: - UIKit fonts
    struct UIKit {
        static func regular(size: CGFloat) -> UIFont {
            return UIFont(name: "Inter28pt-Regular", size: size)!
        }
        
        static func medium(size: CGFloat) -> UIFont {
            return UIFont(name: "Inter28pt-Medium", size: size)!
        }
        
        static func semiBold(size: CGFloat) -> UIFont {
            return UIFont(name: "Inter28pt-SemiBold", size: size)!
        }

        static func bold(size: CGFloat) -> UIFont {
            return UIFont(name: "Inter28pt-Bold", size: size)!
        }
        
        static func light(size: CGFloat) -> UIFont {
            return UIFont(name: "Inter28pt-Light", size: size)!
        }
        
        static func black(size: CGFloat) -> UIFont {
            return UIFont(name: "Inter28pt-Black", size: size)!
        }
        
        static func thin(size: CGFloat) -> UIFont {
            return UIFont(name: "Inter28pt-Thin", size: size)!
        }
        
        static func extraBold(size: CGFloat) -> UIFont {
            return UIFont(name: "Inter28pt-ExtraBold", size: size)!
        }
    }

    // MARK: - SwiftUI fonts
    struct SwiftUI {
        static func regular(size: CGFloat) -> Font {
            Font.custom("Inter28pt-Regular", size: size)
        }

        static func medium(size: CGFloat) -> Font {
            Font.custom("Inter28pt-Medium", size: size)
        }

        static func semiBold(size: CGFloat) -> Font {
            Font.custom("Inter28pt-SemiBold", size: size)
        }

        static func bold(size: CGFloat) -> Font {
            Font.custom("Inter28pt-Bold", size: size)
        }
        static func light(size: CGFloat) -> Font {
            Font.custom("Inter28pt-Bold", size: size)
        }
        
        static func black(size: CGFloat) -> Font {
            Font.custom("Inter28pt-Black", size: size)
        }
        
        static func thin(size: CGFloat) -> Font {
            Font.custom("Inter28pt-Thin", size: size)
        }
        
        static func extraBold(size: CGFloat) -> Font {
            Font.custom("Inter28pt-ExtraBold", size: size)
        }
    }
}
