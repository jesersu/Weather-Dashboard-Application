//
//  TabBarButton.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI

/// Individual tab bar button with animations and haptic feedback
struct TabBarButton: View {
    let item: TabBarItem
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        // swiftlint:disable:next multiple_closures_with_trailing_closure
        Button {
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()

            action()
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // Background circle for selected state
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Icon
                    Image(systemName: item.icon)
                        .font(.system(size: 24, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(
                            isSelected ?
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [.gray, .gray],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .overlay(alignment: .topTrailing) {
                            // Badge
                            if let badgeCount = item.badgeCount, badgeCount > 0 {
                                Text("\(badgeCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -8)
                            }
                        }
                }
                .frame(height: 50)

                // Title
                Text(item.title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .purple : .gray)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityHint(isSelected ? "Selected" : "Tap to switch to \(item.title)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        TabBarButton(item: .search, isSelected: true) {}
        TabBarButton(item: .favorites, isSelected: false) {}
        TabBarButton(item: TabBarItem(id: "test", icon: "star", title: "Test", badgeCount: 5), isSelected: false) {}
    }
    .padding()
}
