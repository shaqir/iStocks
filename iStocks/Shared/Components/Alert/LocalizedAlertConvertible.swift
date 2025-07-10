//
//  LocalizedAlertConvertible.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-09.
//

import Foundation
import SwiftUI

protocol LocalizedAlertConvertible: Error {
    var alert: SharedAlertData { get }
}
