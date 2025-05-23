// Sources/MapPack/MapProviders/Libre/MapLibreProvider+SmoothTracking.swift

import Foundation
import SwiftUI
import MapLibre
import CoreLocation

// MARK: - Location Tracking Manager Enhancement for MapLibre
extension LocationTrackingManager {
    /// Enhanced camera update specifically for smooth location tracking
    private func updateCameraForCurrentLocationSmooth(_ location: CLLocation) {
        guard case .currentLocation(let zoom) = trackingMode else { return }
        
        let targetZoom = zoom ?? trackingZoomLevel ?? defaultZoomLevel
        
        // Check if this is MapLibre provider
        if let mapLibreProvider = mapProvider as? MapLibreProvider {
            // Use enhanced smooth camera update for MapLibre
            let camera = UniversalMapCamera(
                center: location.coordinate,
                zoom: targetZoom,
                animate: true
            )
            mapLibreProvider.updateCamera(to: camera)
        } else {
            let camera = UniversalMapCamera(
                center: location.coordinate,
                zoom: targetZoom,
                animate: true
            )
            mapProvider?.updateCamera(to: camera)
        }
    }
    
    /// Enhanced camera update for marker tracking
    private func updateCameraForMarkerSmooth(_ markerId: String) {
        guard case .marker(let id, let zoom) = trackingMode,
              id == markerId,
              let marker = mapProvider?.marker(byId: markerId) else { return }
        
        let targetZoom = zoom ?? trackingZoomLevel ?? defaultZoomLevel
        
        // Check if this is MapLibre provider
        if let mapLibreProvider = mapProvider as? MapLibreProvider {
            // Use enhanced smooth camera update for MapLibre
            let camera = UniversalMapCamera(
                center: marker.coordinate,
                zoom: targetZoom,
                animate: true
            )
            mapLibreProvider.updateCamera(to: camera)
        } else {
            // Use regular update for Google Maps
            let camera = UniversalMapCamera(
                center: marker.coordinate,
                zoom: targetZoom,
                animate: true
            )
            mapProvider?.updateCamera(to: camera)
        }
    }
    
    /// Override location update handling for smooth tracking
    public func handleLocationUpdateSmooth(_ location: CLLocation) {
        self.currentLocation = location
        
        if case .currentLocation = trackingMode {
            updateCameraForCurrentLocationSmooth(location)
        }
    }
    
    /// Override marker update handling for smooth tracking
    public func handleMarkerUpdateSmooth(_ marker: any UniversalMapMarkerProtocol) {
        if case .marker(let id, _) = trackingMode, id == marker.id {
            updateCameraForMarkerSmooth(marker.id)
        }
    }
}

// MARK: - Location Update Throttling for Smooth Performance
extension LocationTrackingManager {
    
    private static var lastLocationUpdate: Date = Date()
    private static let locationUpdateThreshold: TimeInterval = 0.5 // Update every 0.5 seconds max
    
    /// Throttled location update to prevent too frequent camera changes
    public func handleLocationUpdateThrottled(_ location: CLLocation) {
        let now = Date()
        let timeSinceLastUpdate = now.timeIntervalSince(Self.lastLocationUpdate)
        
        // Only update if enough time has passed or if this is a significant location change
        let previousLocation = self.currentLocation
        let distanceThreshold: CLLocationDistance = 5 // meters
        
        let shouldUpdate = timeSinceLastUpdate >= Self.locationUpdateThreshold ||
                          previousLocation == nil ||
                          location.distance(from: previousLocation!) >= distanceThreshold
        
        if shouldUpdate {
            Self.lastLocationUpdate = now
            handleLocationUpdateSmooth(location)
        }
    }
}
