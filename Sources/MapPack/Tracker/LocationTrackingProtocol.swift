// Sources/MapPack/Models/LocationTracking/LocationTrackingProtocol.swift

import Foundation
import CoreLocation

/// Orientation of the camera while it follows a marker.
public enum MarkerFollowMode: Equatable {
    /// The camera keeps a fixed north-up bearing; only its center follows the marker.
    case northUp
    /// The camera rotates so the marker's `worldHeading` points up (course-up navigation).
    case courseUp
}

/// Represents different tracking modes for the map camera
public enum MapTrackingMode: Equatable {
    case none
    case currentLocation(zoom: Double?)
    case marker(id: String, zoom: Double?)
    
    public static func == (lhs: MapTrackingMode, rhs: MapTrackingMode) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.currentLocation(let zoom1), .currentLocation(let zoom2)):
            return zoom1 == zoom2
        case (.marker(let id1, let zoom1), .marker(let id2, let zoom2)):
            return id1 == id2 && zoom1 == zoom2
        default:
            return false
        }
    }
}

/// Protocol for location tracking capabilities
public protocol LocationTrackingProtocol: AnyObject {
    /// Current tracking mode
    var trackingMode: MapTrackingMode { get }
    
    /// Start tracking current location
    /// - Parameter zoom: Optional zoom level (uses default if nil)
    func trackCurrentLocationOnMap(zoom: Double?)
    
    /// Start tracking a specific marker
    /// - Parameters:
    ///   - markerId: ID of the marker to track
    ///   - zoom: Optional zoom level (uses default if nil)
    ///   - mode: Camera orientation while following (north-up or course-up)
    ///   - pitch: Camera pitch in degrees (0 = looking straight down)
    ///   - followAnimationDuration: Duration used when the follow camera animates
    ///     (north-up moves). When `nil`, the provider's default is used. Course-up
    ///     follows the heading instantly regardless of this value.
    func trackMarker(
        _ markerId: String,
        zoom: Double?,
        mode: MarkerFollowMode,
        pitch: Double,
        followAnimationDuration: TimeInterval?
    )
    
    /// Stop all tracking
    func stopTracking()
    
    /// Called when location updates
    func handleLocationUpdate(_ location: CLLocation)
    
    /// Called when marker position updates
    func handleMarkerUpdate(_ marker: any UniversalMapMarkerProtocol)
}

/// Delegate for location tracking events
public protocol LocationTrackingDelegate: AnyObject {
    func trackingDidStart(mode: MapTrackingMode)
    func trackingDidStop()
    func trackingDidFail(error: Error)
}
