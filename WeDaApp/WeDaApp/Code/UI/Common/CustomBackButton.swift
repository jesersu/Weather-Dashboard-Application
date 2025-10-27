//
//  CustomBackButton.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI

/// Custom styled back button with gradient background and haptic feedback
struct CustomBackButton: View {
    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        Button {
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()

            // Dismiss view
            dismiss()
        } label: {
            ZStack {
                // Gradient background
                Circle()
                    .fill(NavigationStyling.backButtonGradient)
                    .frame(width: NavigationStyling.backButtonSize, height: NavigationStyling.backButtonSize)
                    .shadow(
                        color: AppColors.gradient2.opacity(0.4),
                        radius: 8,
                        x: 0,
                        y: 4
                    )

                // Back icon
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style

/// Button style that scales down on press
private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        VStack {
            Text("Detail View")
                .font(.largeTitle)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                CustomBackButton()
            }
        }
    }
}
