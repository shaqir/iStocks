//
//  Array+Extensions.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import Foundation
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
