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

    @StateObject private var viewModel = HistoryViewModel()

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
                            NavigationLink {
                                WeatherDetailsView(city: item.cityName)
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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.cityName)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack {
                    if let country = item.country {
                        Text(country)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(timeAgoString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: item.searchedAt, relativeTo: Date())
    }
}

#Preview {
    HistoryView()
}
