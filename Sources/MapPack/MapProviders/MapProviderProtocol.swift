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
public protocol MapProviderProtocol {
    /// Initialize the map provider
    init()
    
    var currentLocation: CLLocation? { get }
    
    var markers: [String: any UniversalMapMarkerProtocol] { get }
    
    /// Update the camera position
    func updateCamera(to camera: UniversalMapCamera)
    
    /// Set the map's edge insets
    func setEdgeInsets(_ insets: UniversalMapEdgeInsets)
    
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
    func setMapStyle(_ style: UniversalMapStyle)
    
    /// Show or hide the user's location
    func showUserLocation(_ show: Bool)
    
    /// Enable or disable user tracking mode
    func setUserTrackingMode(_ tracking: Bool)
    
    /// Set the interaction delegate
    func setInteractionDelegate(_ delegate: MapInteractionDelegate?)
    
    /// Focus on specific coordinates with optional zoom level
    func focusMap(on coordinate: CLLocationCoordinate2D, zoom: Double?, animated: Bool)
    
    /// Fit the map to show a specific polyline
    func focusOnPolyline(id: String, padding: UIEdgeInsets, animated: Bool)
    
    func focusOn(coordinates: [CLLocationCoordinate2D], padding: CGFloat, animated: Bool)
    
    func focusOn(coordinates: [CLLocationCoordinate2D], edges: UIEdgeInsets, animated: Bool)
    
    /// Get the SwiftUI view for this map provider
    func makeMapView() -> AnyView
    
    func setInput(input: any UniversalMapInputProvider)
}

public extension MapProviderProtocol {
    func focusOn(coordinates: [CLLocationCoordinate2D], padding: CGFloat, animated: Bool) {
        self.focusOn(coordinates: coordinates, edges: .init(top: padding, left: padding, bottom: padding, right: padding), animated: animated)
    }
}
