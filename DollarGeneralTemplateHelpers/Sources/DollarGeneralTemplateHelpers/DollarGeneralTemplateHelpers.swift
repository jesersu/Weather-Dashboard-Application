// The Swift Programming Language
// https://docs.swift.org/swift-book
import SwiftUI
import Foundation

// MARK: - Logging

public func LogInfo(_ message: String) {
    print("INFO: \(message)")
}

public func LogError(_ message: String) {
    print("ERROR: \(message)")
}

public func LogDebug(_ message: String) {
    #if DEBUG
    print("DEBUG: \(message)")
    #endif
}

// MARK: - Accessibility Identifiers

public enum UITestIDs {
    public enum SearchView: String {
        case searchField = "SearchViewSearchField"
        case searchButton = "SearchViewSearchButton"
        case resultsScrollView = "SearchViewResultsScrollView"
        case suggestionsList = "SearchViewSuggestionsList"
        case suggestionItem = "SearchViewSuggestionItem"
    }

    public enum WeatherDetailsView: String {
        case parent = "WeatherDetailsViewParent"
        case currentWeather = "WeatherDetailsCurrentWeather"
        case forecast = "WeatherDetailsForecast"
        case favoriteButton = "WeatherDetailsFavoriteButton"
    }

    public enum FavoritesView: String {
        case scrollView = "FavoritesViewScrollView"
        case favoriteItem = "FavoritesViewItem"
    }

    public enum HistoryView: String {
        case scrollView = "HistoryViewScrollView"
        case historyItem = "HistoryViewItem"
    }

    public enum Common: String {
        case loadingView = "CommonLoadingView"
        case errorView = "CommonErrorView"
        case retryButton = "CommonRetryButton"
    }
}

// MARK: - Navigation Protocols

public protocol NavigationPathProtocol: Hashable {
    associatedtype Destination: View
    @ViewBuilder var destination: Destination { get }
}

public protocol NavigationStackManager: ObservableObject {
    associatedtype Path: NavigationPathProtocol
    var path: [Path] { get set }
}

public extension View {
    func navigationDestination<Manager: NavigationStackManager>(
        for manager: Manager
    ) -> some View {
        self.navigationDestination(for: Manager.Path.self) { path in
            path.destination
        }
    }
}
