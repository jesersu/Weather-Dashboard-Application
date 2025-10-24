//
//  LoadingView.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI
import DollarGeneralTemplateHelpers

/// Reusable loading indicator view
public struct LoadingView: View {
    let message: String

    public init(message: String = L10n.Common.loading) {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))

            Text(message)
                .font(AppTypography.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .accessibilityIdentifier(UITestIDs.Common.loadingView.rawValue)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading \(message)")
    }
}

#Preview {
    LoadingView()
}

#Preview("Custom Message") {
    LoadingView(message: "Fetching weather data...")
}
