//
//  CustomSearchBar.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI

/// Custom inline search bar with gradient border and floating elevation
struct CustomSearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    let placeholder: String
    let onSubmit: () -> Void
    let onClear: (() -> Void)?

    init(
        text: Binding<String>,
        placeholder: String = "Search for a city...",
        onSubmit: @escaping () -> Void,
        onClear: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSubmit = onSubmit
        self.onClear = onClear
    }

    var body: some View {
        HStack(spacing: 12) {
            // Search icon with gradient
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(NavigationStyling.searchBarGradientBorder)
                .frame(width: 20)

            // Text field
            TextField(placeholder, text: $text)
                .font(AppTypography.body)
                .foregroundColor(.primary)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit {
                    onSubmit()
                }
                .autocorrectionDisabled()

            // Clear button
            if !text.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        text = ""
                        onClear?()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 12)
        .background(
            // White/system background
            RoundedRectangle(cornerRadius: NavigationStyling.searchBarCornerRadius)
                .fill(Color(.systemBackground))
        )
        .overlay(
            // Gradient border
            RoundedRectangle(cornerRadius: NavigationStyling.searchBarCornerRadius)
                .strokeBorder(
                    isFocused ? NavigationStyling.searchBarGradientBorder : LinearGradient(
                        colors: [Color.gray.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: isFocused ? NavigationStyling.searchBarBorderWidth : 1
                )
        )
        .shadow(
            color: isFocused ? AppColors.gradient1.opacity(0.2) : AppColors.cardShadow,
            radius: isFocused ? 12 : 6,
            x: 0,
            y: isFocused ? 6 : 3
        )
        .animation(.easeInOut(duration: 0.3), value: isFocused)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        CustomSearchBar(
            text: .constant(""),
            placeholder: "Search for a city...",
            onSubmit: { print("Submit") }
        )

        CustomSearchBar(
            text: .constant("London"),
            placeholder: "Search for a city...",
            onSubmit: { print("Submit") },
            onClear: { print("Clear") }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
