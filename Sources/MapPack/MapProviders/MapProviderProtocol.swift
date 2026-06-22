//
//  UniversalMapProtocols.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

// UniversalMap/Protocols/MapProviderProtocol.swift
import Foundation
import SwiftUI
import CoreLocation
import UIKit

// MARK: - Interface Segregation Protocols

/// Protocol for controlling the map camera and viewport
public protocol MapCameraControllable: AnyObject {
    /// Update the camera position
    func updateCamera(to camera: UniversalMapCamera)
    
    /// Set the map's edge insets
    func setEdgeInsets(_ insets: UniversalMapEdgeInsets)
    
    /// Set min and max zoom levels
    func setMaxMinZoomLevels(min: Double, max: Double)
    
    /// Focus on specific coordinates with optional zoom level
    func focusMap(on coordinate: CLLocationCoordinate2D, zoom: Double?, animated: Bool)
    
    /// Fit the map to show a specific polyline
    func focusOnPolyline(id: String, padding: UIEdgeInsets, animated: Bool)
    
    func focusOnPolyline(id: String, animated: Bool)
    
    func focusOn(coordinates: [CLLocationCoordinate2D], padding: CGFloat, animated: Bool)
    
    func focusOn(coordinates: [CLLocationCoordinate2D], edges: UIEdgeInsets, animated: Bool)
    
    @MainActor
    func zoomOut(minLevel: Float, shift: Double)
}

/// Protocol for managing markers on the map
public protocol MapMarkerManageable: AnyObject {
    var markers: [String: any UniversalMapMarkerProtocol] { get }
    
    /// Add a marker to the map
    func addMarker(_ marker: any UniversalMapMarkerProtocol)
    
    func marker(byId id: String) -> (any UniversalMapMarkerProtocol)?
    
    /// Update a marker on the map
    func updateMarker(_ marker: any UniversalMapMarkerProtocol)
    
    /// Remove a marker from the map
    func removeMarker(withId id: String)
    
    /// Remove all markers from the map
    func clearAllMarkers()
}

/// Protocol for managing polylines on the map
public protocol MapPolylineManageable: AnyObject {
    var polylines: [String: UniversalMapPolyline] { get }
    
    /// Add a polyline to the map
    func addPolyline(_ polyline: UniversalMapPolyline, animated: Bool)
    
    /// Update an existing polyline on the map
    func updatePolyline(_ polyline: UniversalMapPolyline, animated: Bool)
    
    /// Update an existing polyline's coordinates
    func updatePolyline(id: String, coordinates: [CLLocationCoordinate2D], animated: Bool)
    
    /// Remove a polyline from the map
    func removePolyline(withId id: String)
    
    /// Remove all polylines from the map
    func clearAllPolylines()
}

/// Protocol for managing user location display and tracking
public protocol MapUserLocationDisplayable: AnyObject {
    var currentLocation: CLLocation? { get }

    /// Whether a custom current-location icon is currently set on this provider.
    ///
    /// Drives how `UniversalMapViewModel` applies a user-tracking mode: when `true`, the
    /// SDK's native tracking can't follow the icon (Google renders it as a separate
    /// marker), so the camera is driven by the in-house `LocationTrackingManager`
    /// follow instead of `setUserTrackingMode(mode:)`. Declared as a protocol
    /// requirement so it dispatches to each provider rather than the default below.
    var hasCustomUserLocationIcon: Bool { get }

    /// Show or hide the user's location
    func showUserLocation(_ show: Bool)
    
    /// Enable or disable user tracking mode
    func setUserTrackingMode(mode: UserLocationtrackingMode)
    
    func setUserLocationIcon(_ image: UIImage?, scale: CGFloat)
    
    func updateUserLocation(_ location: CLLocation)
    
    func showUserLocationAccuracy(_ show: Bool)
}

/// Protocol for styling the map
public protocol MapStylable: AnyObject {
    /// set preferred refresh rate
    func set(preferredRefreshRate: MapRefreshRate)
    
    /// Set the map style
    func setMapStyle(_ style: (any UniversalMapStyleProtocol)?, scheme: ColorScheme)

    /// Set the native map view tint color.
    @MainActor
    func setTintColor(_ color: UIColor)
    
    func showBuildings(_ show: Bool)
    
    func setConfig(_ config: any UniversalMapConfigProtocol)
}

/// Protocol for map interaction handling
public protocol MapInteractable: AnyObject {
    /// Set the interaction delegate
    func setInteractionDelegate(_ delegate: MapInteractionDelegate?)
    
    @MainActor
    func set(disabled: Bool)
}

/// Protocol for creating the map view
public protocol MapViewable: AnyObject {
    /// Get the SwiftUI view for this map provider
    func makeMapView() -> AnyView
}

/// Protocol for creating a native UIKit view controller for the map provider.
///
/// This is the UIKit counterpart of ``MapViewable``. SwiftUI hosts use
/// ``MapViewable/makeMapView()``; UIKit hosts use ``makeMapViewController()``.
public protocol MapUIKitViewable: AnyObject {
    /// Returns a `UIViewController` hosting the provider's native map, for UIKit integration.
    @MainActor
    func makeMapViewController() -> UIViewController
}

// MARK: - Capabilities

/// Defines the capabilities supported by a map provider
public struct MapCapabilities: OptionSet, Sendable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// Supports native user tracking modes (e.g. follow with heading)
    public static let userTrackingMode = MapCapabilities(rawValue: 1 << 0)
    
    /// Supports showing 3D buildings
    public static let buildings = MapCapabilities(rawValue: 1 << 1)
    
    /// Supports changing map style dynamically
    public static let styling = MapCapabilities(rawValue: 1 << 2)
    
    /// Supports polyline manipulation
    public static let polylines = MapCapabilities(rawValue: 1 << 3)
}

// MARK: - Main Protocol

/// Protocol defining the common interface for map providers
/// Adheres to Interface Segregation Principle by composing smaller protocols
public protocol MapProviderProtocol: NSObject, MapCameraControllable, MapMarkerManageable, MapPolylineManageable, MapUserLocationDisplayable, MapStylable, MapInteractable, MapViewable, MapUIKitViewable {
    
    /// The capabilities supported by this provider
    var capabilities: MapCapabilities { get }
    
    /// Initialize the map provider
    init()
}

// MARK: - Default Extensions

public extension MapCameraControllable {
    func focusOn(coordinates: [CLLocationCoordinate2D], padding: CGFloat, animated: Bool) {
        self.focusOn(coordinates: coordinates, edges: .init(top: padding, left: padding, bottom: padding, right: padding), animated: animated)
    }
}

public extension MapProviderProtocol {
    /// Convenience overloads that default to an animated focus and forward to the
    /// provider's real implementation, rather than silently doing nothing.

    func focusOnPolyline(id: String, padding: UIEdgeInsets) {
        focusOnPolyline(id: id, padding: padding, animated: true)
    }

    func focusOnPolyline(id: String) {
        focusOnPolyline(id: id, animated: true)
    }
}

public extension MapUserLocationDisplayable {
    /// Providers without a custom-icon concept report `false`, so the view model always
    /// falls back to native tracking for them.
    var hasCustomUserLocationIcon: Bool { false }

    func setUserLocationIcon(_ image: UIImage?, scale: CGFloat) {}

    func updateUserLocation(_ location: CLLocation) {}

    func showUserLocationAccuracy(_ show: Bool) {}
}

public extension MapUIKitViewable where Self: MapViewable {
    /// Default UIKit bridge: hosts the provider's SwiftUI map in a `UIHostingController`.
    ///
    /// Providers should override this to vend their native view controller directly and
    /// avoid the extra SwiftUI layer.
    @MainActor
    func makeMapViewController() -> UIViewController {
        let host = UIHostingController(rootView: makeMapView())
        host.view.backgroundColor = .clear
        return host
    }
}
