//
//  UniversalMapView.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

// UniversalMap/UniversalMapView.swift
import SwiftUI
import CoreLocation

/// The main SwiftUI map component that displays either Google Maps or MapLibre
public struct UniversalMapView: View {
    /// The view model that manages the map state and operations
    @ObservedObject private var viewModel: UniversalMapViewModel
    
    /// Initialize with a specific map provider (defaults to Google Maps)
    public init(provider: MapProvider, input: (any UniversalMapInputProvider)?) {
        self.viewModel = UniversalMapViewModel(mapProvider: provider, input: input)
    }
    
    /// Initialize with an existing view model
    public init(viewModel: UniversalMapViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack {
            // Display the map view from the current provider
            viewModel.makeMapView()
                .ignoresSafeArea(edges: .all)
                .overlay {
                    PinView(vm: viewModel.pinModel)
                        .padding(.bottom, viewModel.pinViewBottomOffset)
                }
            // You can overlay additional controls or UI elements here
        }
    }
    
    // MARK: - Public API for modifying the map
    
    /// Change the map provider
    public func mapProvider(_ provider: MapProvider) -> Self {
        viewModel.setMapProvider(provider)
        return self
    }
    
    /// Set the camera position
    public func camera(_ camera: UniversalMapCamera) -> Self {
        viewModel.updateCamera(to: camera)
        return self
    }
    
    /// Set the map style
    public func mapStyle(_ style: UniversalMapStyle) -> Self {
        viewModel.setMapStyle(style)
        return self
    }
    
    /// Show or hide user location
    public func showsUserLocation(_ show: Bool) -> Self {
        viewModel.showUserLocation(show)
        return self
    }
    
    /// Enable or disable user tracking mode
    public func userTrackingMode(_ tracking: Bool) -> Self {
        viewModel.setUserTrackingMode(tracking)
        return self
    }
    
    /// Set the map's edge insets
    public func edgeInsets(_ insets: UniversalMapEdgeInsets) -> Self {
        viewModel.setEdgeInsets(insets)
        return self
    }
    
    /// Focus on a specific coordinate
    public func focus(on coordinate: CLLocationCoordinate2D, zoom: Double? = nil) -> Self {
        viewModel.focusMap(on: coordinate, zoom: zoom)
        return self
    }
}
