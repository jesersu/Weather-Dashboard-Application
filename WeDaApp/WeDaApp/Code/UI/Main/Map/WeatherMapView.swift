//
//  WeatherMapView.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI
import MapKit

/// Interactive weather map showing favorite cities with OpenWeatherMap overlay tiles
///
/// **Features**:
/// - Display all favorite cities as annotations
/// - Show current weather for each city
/// - Toggle between weather layers (Temperature, Precipitation, Clouds)
/// - Tap annotations to view details
/// - OpenWeatherMap tile overlays for visualization
///
/// **Map Layers**:
/// - Temperature: Color-coded temperature map
/// - Precipitation: Rainfall intensity
/// - Clouds: Cloud coverage
struct WeatherMapView: View {

    @StateObject private var viewModel = WeatherMapViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            // Map with annotations and overlay
            MapViewRepresentable(
                region: $viewModel.region,
                annotations: viewModel.annotations,
                overlay: viewModel.selectedOverlay
            )
            .ignoresSafeArea()

            // Overlay selector
            VStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView("Loading weather data...")
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground).opacity(0.9))
                        )
                }

                // Overlay toggle
                HStack(spacing: 16) {
                    ForEach(WeatherMapOverlay.allCases, id: \.self) { overlay in
                        Button {
                            viewModel.changeOverlay(to: overlay)
                        } label: {
                            Text(overlay.displayName)
                                .font(.caption)
                                .fontWeight(viewModel.selectedOverlay == overlay ? .bold : .regular)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(viewModel.selectedOverlay == overlay ? Color.blue : Color(.secondarySystemBackground))
                                )
                                .foregroundColor(viewModel.selectedOverlay == overlay ? .white : .primary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground).opacity(0.9))
                )

                // Attribution
                Text("Weather data © OpenWeatherMap")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Weather Map")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadFavorites()
        }
    }
}

// MARK: - MapView UIViewRepresentable

/// UIViewRepresentable wrapper for MKMapView with custom tile overlay
struct MapViewRepresentable: UIViewRepresentable {

    @Binding var region: MKCoordinateRegion
    let annotations: [WeatherAnnotation]
    let overlay: WeatherMapOverlay

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.mapType = .standard
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region
        mapView.setRegion(region, animated: true)

        // Update annotations
        let currentAnnotations = mapView.annotations.filter { $0 is WeatherAnnotation }
        mapView.removeAnnotations(currentAnnotations)
        mapView.addAnnotations(annotations)

        // Update overlay
        mapView.removeOverlays(mapView.overlays)
        let tileOverlay = OpenWeatherMapTileOverlay(layer: overlay)
        mapView.addOverlay(tileOverlay, level: .aboveLabels)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, MKMapViewDelegate {

        // MARK: - Annotation Views

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Don't customize user location annotation
            guard annotation is WeatherAnnotation else { return nil }

            let identifier = "WeatherAnnotation"
            var view: MKMarkerAnnotationView

            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
                view = dequeuedView
                view.annotation = annotation
            } else {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)

                // Add detail button
                let detailButton = UIButton(type: .detailDisclosure)
                view.rightCalloutAccessoryView = detailButton
            }

            // Customize marker appearance
            view.markerTintColor = .systemBlue
            view.glyphText = "🌡️"

            return view
        }

        // MARK: - Overlay Rendering

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tileOverlay = overlay as? MKTileOverlay {
                let renderer = MKTileOverlayRenderer(tileOverlay: tileOverlay)
                renderer.alpha = 0.6 // Semi-transparent overlay
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        // MARK: - Callout Accessory Tapped

        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            // Handle tap on detail button
            // In a real implementation, navigate to WeatherDetailsView
            if let annotation = view.annotation as? WeatherAnnotation {
                print("📍 Tapped annotation for: \(annotation.cityName)")
                // TODO: Navigate to WeatherDetailsView
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WeatherMapView()
    }
}
