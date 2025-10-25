//
//  CustomNavigationBar.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI

/// Custom navigation bar appearance with gradient background and blur effect
struct CustomNavigationBarModifier: ViewModifier {
    let showGradient: Bool

    init(showGradient: Bool = true) {
        self.showGradient = showGradient
    }

    func body(content: Content) -> some View {
        content
            .toolbarBackground(showGradient ? .visible : .automatic, for: .navigationBar)
            .toolbarBackground(
                showGradient ?
                    AnyShapeStyle(
                        AppGradients.navigationBar
                            .shadow(.drop(color: AppColors.cardShadow, radius: 8, y: 4))
                    ) :
                    AnyShapeStyle(.ultraThinMaterial),
                for: .navigationBar
            )
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

extension View {
    /// Apply custom navigation bar styling with gradient background
    func customNavigationBar(showGradient: Bool = true) -> some View {
        self.modifier(CustomNavigationBarModifier(showGradient: showGradient))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<20) { index in
                    Text("Item \(index)")
                        .font(.title)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Custom Nav Bar")
        .navigationBarTitleDisplayMode(.large)
        .customNavigationBar()
    }
}
