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

/// Protocol defining the common interface for map providers
public protocol MapProviderProtocol: NSObject {
    /// Initialize the map provider
    init()
    
    var currentLocation: CLLocation? { get }
    
    var markers: [String: any UniversalMapMarkerProtocol] { get }
    
    var polylines: [String: UniversalMapPolyline] { get }
    
    /// Update the camera position
    func updateCamera(to camera: UniversalMapCamera)
    
    /// Set the map's edge insets
    func setEdgeInsets(_ insets: UniversalMapEdgeInsets)
    
    /// set preferred refresh rate
    func set(preferredRefreshRate: MapRefreshRate)
    
    /// Add a marker to the map
    func addMarker(_ marker: any UniversalMapMarkerProtocol)
    
    func marker(byId id: String) -> (any UniversalMapMarkerProtocol)?
    
    /// Add a marker to the map
    func updateMarker(_ marker: any UniversalMapMarkerProtocol)
    
    /// Remove a marker from the map
    func removeMarker(withId id: String)
    
    /// Remove all markers from the map
    func clearAllMarkers()
    
    /// Add a polyline to the map
    func addPolyline(_ polyline: UniversalMapPolyline)
    
    /// Remove a polyline from the map
    func removePolyline(withId id: String)
    
    /// Remove all polylines from the map
    func clearAllPolylines()
    
    /// Set the map style
    func setMapStyle(_ style: (any UniversalMapStyleProtocol)?, scheme: ColorScheme)
    
    /// Show or hide the user's location
    func showUserLocation(_ show: Bool)
    
    func showBuildings(_ show: Bool)
    
    func setMaxMinZoomLevels(min: Double, max: Double)
    
    /// Enable or disable user tracking mode
    func setUserTrackingMode(_ tracking: Bool)
    
    /// Set the interaction delegate
    func setInteractionDelegate(_ delegate: MapInteractionDelegate?)
    
    /// Focus on specific coordinates with optional zoom level
    func focusMap(on coordinate: CLLocationCoordinate2D, zoom: Double?, animated: Bool)
    
    /// Fit the map to show a specific polyline
    func focusOnPolyline(id: String, padding: UIEdgeInsets, animated: Bool)
    
    func focusOnPolyline(id: String, animated: Bool)
    
    func focusOn(coordinates: [CLLocationCoordinate2D], padding: CGFloat, animated: Bool)
    
    func focusOn(coordinates: [CLLocationCoordinate2D], edges: UIEdgeInsets, animated: Bool)
    
    @MainActor
    func set(disabled: Bool) 
    
    /// Get the SwiftUI view for this map provider
    func makeMapView() -> AnyView
    
    func setConfig(_ config: any UniversalMapConfigProtocol)
    
    @MainActor
    func zoomOut(minLevel: Float, shift: Double)
    
    func setUserLocationIcon(_ image: UIImage, scale: CGFloat)
    
    func updateUserLocation(_ location: CLLocation)
    
    func showUserLocationAccuracy(_ show: Bool)
}

public extension MapProviderProtocol {
    func focusOn(coordinates: [CLLocationCoordinate2D], padding: CGFloat, animated: Bool) {
        self.focusOn(coordinates: coordinates, edges: .init(top: padding, left: padding, bottom: padding, right: padding), animated: animated)
    }
    
    func focusOnPolyline(id: String, padding: UIEdgeInsets) {
        
    }
    
    func focusOnPolyline(id: String) {
        
    }
    
    func setUserLocationIcon(_ image: UIImage, scale: CGFloat) {}
    
    func updateUserLocation(_ location: CLLocation) {}
    
    func showUserLocationAccuracy(_ show: Bool) {}
}
