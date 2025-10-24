//
//  Font+Custom.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI

extension Font {
    /// Inter font family with fallback to system font
    /// Usage: .font(.inter(16, weight: .semibold))
    static func inter(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let fontName: String
        switch weight {
        case .bold, .heavy, .black:
            fontName = "Inter-Bold"
        case .semibold:
            fontName = "Inter-SemiBold"
        case .medium:
            fontName = "Inter-Medium"
        default:
            fontName = "Inter-Regular"
        }

        // Try custom font, fallback to system if not available
        if UIFont(name: fontName, size: size) != nil {
            return .custom(fontName, size: size)
        } else {
            // Fallback to system font with similar weight
            return .system(size: size, weight: weight, design: .default)
        }
    }
}
