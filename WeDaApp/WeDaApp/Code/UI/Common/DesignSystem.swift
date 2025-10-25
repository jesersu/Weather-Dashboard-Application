//
//  DesignSystem.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI

// MARK: - Colors

enum AppColors {
    // Primary Colors
    static let primary = Color(hex: "007AFF")
    static let primaryDark = Color(hex: "0051D5")

    // Gradient Colors
    static let gradient1 = Color(hex: "667EEA")
    static let gradient2 = Color(hex: "764BA2")
    static let gradientLight1 = Color(hex: "89A7FF")
    static let gradientLight2 = Color(hex: "9B71CE")

    // Background Colors
    static let cardBackground = Color(.secondarySystemBackground)
    static let surfaceBackground = Color(.systemBackground)

    // Weather-specific Gradients
    static let sunnyStart = Color(hex: "FFD93D")
    static let sunnyEnd = Color(hex: "FF9F1C")
    static let cloudyStart = Color(hex: "A8DADC")
    static let cloudyEnd = Color(hex: "457B9D")
    static let rainyStart = Color(hex: "5E7CE2")
    static let rainyEnd = Color(hex: "3B5BA5")

    // Semantic Colors
    static let success = Color(hex: "34C759")
    static let warning = Color(hex: "FF9500")
    static let error = Color(hex: "FF3B30")

    // Shadow
    static let cardShadow = Color.black.opacity(0.08)
    static let strongShadow = Color.black.opacity(0.15)
}

// MARK: - Spacing

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

enum AppRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xLarge: CGFloat = 20
    static let xxLarge: CGFloat = 28
}

// MARK: - Typography

enum AppTypography {
    // Display (Extra Large)
    static let display = Font.inter(44, weight: .bold)
    static let displayMedium = Font.inter(40, weight: .bold)

    // Titles
    static let largeTitle = Font.inter(34, weight: .bold)
    static let title = Font.inter(28, weight: .bold)
    static let title2 = Font.inter(24, weight: .bold)
    static let title3 = Font.inter(20, weight: .semibold)

    // Headings
    static let headline = Font.inter(20, weight: .semibold)
    static let subheadline = Font.inter(16, weight: .semibold)

    // Body
    static let body = Font.inter(16, weight: .regular)
    static let bodyMedium = Font.inter(16, weight: .medium)
    static let bodyBold = Font.inter(16, weight: .bold)

    // Captions
    static let caption = Font.inter(14, weight: .regular)
    static let caption2 = Font.inter(12, weight: .regular)
    static let captionBold = Font.inter(14, weight: .semibold)

    // Special
    static let weatherTemp = Font.inter(64, weight: .thin)
    static let weatherTempLarge = Font.inter(80, weight: .thin)
}

// MARK: - Shadows

enum AppShadow {
    static let small = Shadow(
        color: AppColors.cardShadow,
        radius: 4,
        x: 0,
        y: 2
    )

    static let medium = Shadow(
        color: AppColors.cardShadow,
        radius: 8,
        x: 0,
        y: 4
    )

    static let large = Shadow(
        color: AppColors.strongShadow,
        radius: 16,
        x: 0,
        y: 8
    )

    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

// MARK: - Gradients

enum AppGradients {
    static let primary = LinearGradient(
        colors: [AppColors.gradient1, AppColors.gradient2],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let sunny = LinearGradient(
        colors: [AppColors.sunnyStart, AppColors.sunnyEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cloudy = LinearGradient(
        colors: [AppColors.cloudyStart, AppColors.cloudyEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let rainy = LinearGradient(
        colors: [AppColors.rainyStart, AppColors.rainyEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let subtle = LinearGradient(
        colors: [Color.white.opacity(0.9), Color.white.opacity(0.6)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let navigationBar = LinearGradient(
        colors: [AppColors.gradient1.opacity(0.9), AppColors.gradient2.opacity(0.9)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Navigation Styling

enum NavigationStyling {
    // Back Button
    static let backButtonSize: CGFloat = 40
    static let backButtonGradient = LinearGradient(
        colors: [AppColors.gradient1, AppColors.gradient2],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Search Bar
    static let searchBarHeight: CGFloat = 44
    static let searchBarCornerRadius: CGFloat = 16
    static let searchBarBorderWidth: CGFloat = 2
    static let searchBarGradientBorder = LinearGradient(
        colors: [AppColors.gradient1.opacity(0.5), AppColors.gradient2.opacity(0.5)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - View Modifier Extensions

extension View {
    /// Apply app's standard card style
    func appCardStyle() -> some View {
        self
            .padding(AppSpacing.lg)
            .background(AppColors.cardBackground)
            .cornerRadius(AppRadius.xLarge)
            .shadow(
                color: AppShadow.medium.color,
                radius: AppShadow.medium.radius,
                x: AppShadow.medium.x,
                y: AppShadow.medium.y
            )
    }

    /// Apply gradient card style
    func appGradientCard(gradient: LinearGradient = AppGradients.primary) -> some View {
        self
            .padding(AppSpacing.lg)
            .background(gradient)
            .cornerRadius(AppRadius.xLarge)
            .shadow(
                color: AppShadow.large.color,
                radius: AppShadow.large.radius,
                x: AppShadow.large.x,
                y: AppShadow.large.y
            )
    }
}
