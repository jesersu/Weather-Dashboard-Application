//
//  ErrorView.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI
import NetworkingKit
import DollarGeneralTemplateHelpers

/// Reusable error display view with retry functionality
public struct ErrorView: View {
    let error: APIError
    let retryAction: () -> Void

    public init(error: APIError, retryAction: @escaping () -> Void) {
        self.error = error
        self.retryAction = retryAction
    }

    public var body: some View {
        VStack(spacing: 24) {
            Image(systemName: errorIcon)
                .font(.system(size: 60))
                .foregroundColor(errorColor)

            VStack(spacing: 8) {
                Text(errorTitle)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(error.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button(action: retryAction) {
                Label(L10n.Common.retry, systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .accessibilityIdentifier(UITestIDs.Common.retryButton.rawValue)
            .accessibilityHint("Tap to retry the failed operation")
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .accessibilityIdentifier(UITestIDs.Common.errorView.rawValue)
        .accessibilityElement(children: .contain)
    }

    private var errorIcon: String {
        switch error {
        case .noInternetConnection:
            return "wifi.slash"
        case .invalidCity:
            return "location.slash"
        case .serverError:
            return "exclamationmark.triangle"
        case .unknownError:
            return "questionmark.circle"
        }
    }

    private var errorTitle: String {
        switch error {
        case .noInternetConnection:
            return L10n.Error.noInternet
        case .invalidCity:
            return L10n.Error.invalidCity
        case .serverError:
            return L10n.Error.serverError
        case .unknownError:
            return L10n.Error.unknown
        }
    }

    private var errorColor: Color {
        switch error {
        case .noInternetConnection:
            return .orange
        case .invalidCity:
            return .purple
        case .serverError:
            return .red
        case .unknownError:
            return .gray
        }
    }
}

#Preview("No Internet") {
    ErrorView(error: .noInternetConnection) {
        print("Retry tapped")
    }
}

#Preview("Invalid City") {
    ErrorView(error: .invalidCity) {
        print("Retry tapped")
    }
}

#Preview("Server Error") {
    ErrorView(error: .serverError(statusCode: 500, response: "Internal Server Error")) {
        print("Retry tapped")
    }
}
