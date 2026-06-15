//
//  UniversalMapConfiguring.swift
//  IMap
//
//  Chainable configuration API shared by the UIKit entry points
//  (`UniversalMapViewController` and `UniversalMapContainerView`), mirroring the
//  modifiers on the SwiftUI `UniversalMapView`. Each method forwards to the shared
//  `UniversalMapViewModel`, so there is a single source of behaviour (DRY).
//

import SwiftUI
import CoreLocation

/// A UIKit map host backed by a ``UniversalMapViewModel``.
@MainActor
public protocol UniversalMapConfiguring: AnyObject {
    var viewModel: UniversalMapViewModel { get }
}

public extension UniversalMapConfiguring {
    /// Set the camera position.
    @discardableResult
    func camera(_ camera: UniversalMapCamera) -> Self {
        viewModel.updateCamera(to: camera)
        return self
    }

    /// Set the map style for the given color scheme.
    @discardableResult
    func mapStyle(_ style: any UniversalMapStyleProtocol, scheme: ColorScheme) -> Self {
        viewModel.setMapStyle(style, scheme: scheme)
        return self
    }

    /// Show or hide the user's location.
    @discardableResult
    func showsUserLocation(_ show: Bool) -> Self {
        viewModel.showUserLocation(show)
        return self
    }

    /// Enable or disable user tracking mode.
    @discardableResult
    func userTrackingMode(_ tracking: Bool) -> Self {
        viewModel.setUserTrackingMode(tracking)
        return self
    }

    /// Set the map's edge insets.
    @discardableResult
    func edgeInsets(_ insets: UniversalMapEdgeInsets) -> Self {
        viewModel.setEdgeInsets(insets)
        return self
    }

    /// Focus the map on a specific coordinate.
    @discardableResult
    func focus(on coordinate: CLLocationCoordinate2D, zoom: Double? = nil) -> Self {
        viewModel.focusMap(on: coordinate, zoom: zoom)
        return self
    }
}
