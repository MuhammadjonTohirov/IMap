//
//  UniversalMapView.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

// UniversalMap/UniversalMapView.swift
import SwiftUI
import CoreLocation
import Combine

/// The main SwiftUI map component that displays either Google Maps or MapLibre
public struct UniversalMapView: View {
    /// The view model that manages the map state and operations
    @ObservedObject private var viewModel: UniversalMapViewModel
    
    @Environment(\.colorScheme)
    var colorScheme: ColorScheme
    
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
            viewModel.makeMapView()
                .ignoreSafeArea(if: self.viewModel.mapProvider == .google)
                .overlay {
                    ZStack {
                        addressView
                            .padding(.bottom, viewModel.pinViewBottomOffset + 200)
                            .visibility(viewModel.hasAddressView)
                        
                        PinView(vm: viewModel.pinModel)
                            .visibility(viewModel.hasAddressPicker)
                            .padding(.bottom, viewModel.pinViewBottomOffset)
                    }
                }
                .ignoreSafeArea(if: self.viewModel.mapProvider == .mapLibre)
        }
    }
    
    private var addressView: some View {
        Text(viewModel.addressInfo?.name ?? "Loading...")
            .foregroundStyle(.white)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .font(.system(size: 14, weight: .medium))
            .background {
                Capsule()
                    .foregroundStyle(.black)
            }
            .clipShape(Capsule())
            .animation(viewModel.config.hasAddressChangeAnimation ? .default : nil, value: viewModel.addressInfo?.name)
    }
    
    // MARK: - Public API for modifying the map
    
    /// Change the map provider
    public func mapProvider(_ provider: MapProvider) -> Self {
        viewModel.setMapProvider(provider, input: nil)
        return self
    }
    
    /// Set the camera position
    public func camera(_ camera: UniversalMapCamera) -> Self {
        viewModel.updateCamera(to: camera)
        return self
    }
    
    /// Set the map style
    public func mapStyle(_ style: any UniversalMapStyleProtocol) -> Self {
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

private extension View {
    func ignoreSafeArea(edge: UIEdgeInsets = .zero, if condition: Bool) -> some View {
        if condition {
            return AnyView(self.ignoresSafeArea())
        }
        
        return AnyView(self)
    }
}
