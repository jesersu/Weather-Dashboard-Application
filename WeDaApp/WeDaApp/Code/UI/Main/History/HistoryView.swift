//
//  HistoryView.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI
import DollarGeneralPersist
import DollarGeneralTemplateHelpers

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @State private var selectedCity: String?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.history.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.purple.gradient)

                        Text("No History")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Your recent searches will appear here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        ForEach(viewModel.history) { item in
                            Button {
                                selectedCity = item.cityName
                            } label: {
                                HistoryItemView(item: item)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .accessibilityIdentifier(UITestIDs.HistoryView.historyItem.rawValue)
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                let item = viewModel.history[index]
                                viewModel.deleteHistoryItem(id: item.id)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .safeAreaInset(edge: .bottom) {
                        Spacer()
                            .frame(height: 100)
                    }
                    .accessibilityIdentifier(UITestIDs.HistoryView.scrollView.rawValue)
                }
            }
            .navigationDestination(item: $selectedCity) { city in
                WeatherDetailsView(city: city)
            }
            .navigationTitle("History")
            .toolbar {
                if !viewModel.history.isEmpty {
                    Button("Clear") {
                        viewModel.clearHistory()
                    }
                }
            }
            .onAppear {
                viewModel.loadHistory()
            }
        }
    }
}

private struct HistoryItemView: View {
    let item: SearchHistoryItem

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Gradient Clock Badge
            ZStack {
                Circle()
                    .fill(AppGradients.primary)
                    .frame(width: 40, height: 40)

                Image(systemName: "clock.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: AppShadow.small.color,
                    radius: AppShadow.small.radius,
                    x: AppShadow.small.x,
                    y: AppShadow.small.y)

            // Content
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(item.cityName)
                    .font(AppTypography.headline)
                    .foregroundColor(.primary)

                HStack(spacing: AppSpacing.xs) {
                    if let country = item.country {
                        Text(country)
                            .font(AppTypography.subheadline)
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(AppTypography.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text(timeAgoString)
                        .font(AppTypography.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .strokeBorder(AppGradients.primary.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: AppShadow.medium.color,
                radius: AppShadow.medium.radius,
                x: AppShadow.medium.x,
                y: AppShadow.medium.y)
    }

    // MARK: - Computed Properties

    private var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Searched " + formatter.localizedString(for: item.searchedAt, relativeTo: Date())
    }
}

#Preview {
    HistoryView(viewModel: HistoryViewModel())
}
