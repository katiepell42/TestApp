//
//  Colors.swift
//  TesetApp
//
//  Created by Katie Pell on 3/18/25.
//

import SwiftUI

// Custom colors defined using RGB or Hex
extension Color {
    static let lightGreen = Color(hex: "#74c476")
    static let darkGreen = Color(hex: "#238b45")
//    static let customYellow = Color("CustomYellow") // If using Asset colors
}

// Helper function to create colors from Hex code
extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
