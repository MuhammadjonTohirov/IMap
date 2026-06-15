// Sources/MapPack/Models/LocationTracking/LocationTrackingManager.swift

import Foundation
import CoreLocation
import Combine

/// Centralized location tracking manager
public class LocationTrackingManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published public private(set) var trackingMode: MapTrackingMode = .none
    @Published public var currentLocation: CLLocation?
    @Published public private(set) var isTrackingActive: Bool = false
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private(set) weak var mapProvider: MapProviderProtocol?
    private(set) weak var delegate: LocationTrackingDelegate?
    
    private(set) var defaultZoomLevel: Double = 17
    private(set) var trackingZoomLevel: Double?

    // MARK: - Marker Follow Configuration
    private(set) var markerFollowMode: MarkerFollowMode = .northUp
    private(set) var markerFollowPitch: Double = 0
    private(set) var markerFollowAnimationDuration: TimeInterval?

    // MARK: - Location Update Throttling
    /// Timestamp of the last applied location update; drives time-based throttling.
    private var lastThrottledLocationUpdate: Date?
    /// Minimum interval between throttled camera updates.
    private let locationUpdateThrottleInterval: TimeInterval = 0.5
    /// Distance (meters) that forces an immediate update regardless of the interval.
    private let locationUpdateDistanceThreshold: CLLocationDistance = 5

    // MARK: - Initialization
    public override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Public Methods
    
    /// Set the map provider to control
    public func setMapProvider(_ provider: MapProviderProtocol) {
        self.mapProvider = provider
    }
    
    /// Set the tracking delegate
    public func setDelegate(_ delegate: LocationTrackingDelegate?) {
        self.delegate = delegate
    }
    
    /// Set default zoom level for tracking
    public func setDefaultZoomLevel(_ zoom: Double) {
        self.defaultZoomLevel = zoom
    }
    
    // MARK: - Private Methods
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // Update every 5 meters
        
        // Request permission immediately if not determined
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    private func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            Logging.l(tag: "LocationTracking", "Requesting location permission...")
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            Logging.l(tag: "LocationTracking", "Location permission denied or restricted")
            let error = NSError(domain: "LocationTracking", code: 1, userInfo: [NSLocalizedDescriptionKey: "Location permission denied. Please enable location access in Settings."])
            delegate?.trackingDidFail(error: error)
            stopTracking()
        case .authorizedWhenInUse, .authorizedAlways:
            Logging.l(tag: "LocationTracking", "Location permission granted, starting updates...")
            locationManager.startUpdatingLocation()
        @unknown default:
            Logging.l(tag: "LocationTracking", "Unknown authorization status")
            break
        }
    }
    
    private func startLocationUpdates() {
        Task {
            guard CLLocationManager.locationServicesEnabled() else {
                let error = NSError(domain: "LocationTracking", code: 2, userInfo: [NSLocalizedDescriptionKey: "Location services disabled"])
                delegate?.trackingDidFail(error: error)
                return
            }
            
            Task { @MainActor in
                self.requestLocationPermission()
            }
        }
    }
    
    private func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    private func updateCameraForCurrentLocation(_ location: CLLocation) {
        guard case .currentLocation(let zoom) = trackingMode else { return }
        
        let targetZoom = zoom ?? trackingZoomLevel ?? defaultZoomLevel
        let camera = UniversalMapCamera(
            center: location.coordinate,
            zoom: targetZoom,
            animate: true
        )
        
        mapProvider?.updateCamera(to: camera)
    }
    
    private func updateCameraForMarker(_ markerId: String) {
        guard case .marker(let id, let zoom) = trackingMode,
              id == markerId,
              let marker = mapProvider?.marker(byId: markerId) else { return }

        let targetZoom = zoom ?? trackingZoomLevel ?? defaultZoomLevel
        let isCourseUp = markerFollowMode == .courseUp

        // Course-up follows the heading instantly so the map reacts immediately.
        // North-up eases toward the target, which also animates the bearing back
        // to north when leaving course-up.
        let camera = UniversalMapCamera(
            center: marker.coordinate,
            zoom: targetZoom,
            bearing: isCourseUp ? marker.worldHeading : 0,
            pitch: markerFollowPitch,
            animate: !isCourseUp,
            animationDuration: isCourseUp ? nil : markerFollowAnimationDuration
        )

        mapProvider?.updateCamera(to: camera)
    }
}

// MARK: - LocationTrackingProtocol Implementation
extension LocationTrackingManager: LocationTrackingProtocol {
    
    public func trackCurrentLocationOnMap(zoom: Double? = nil) {
        let defaultZoomLevel = self.defaultZoomLevel
        Logging.l(tag: "LocationTracking", "Starting current location tracking with zoom: \(zoom ?? defaultZoomLevel)")
        
        trackingMode = .currentLocation(zoom: zoom)
        trackingZoomLevel = zoom
        isTrackingActive = true
        
        // Enable user location on the map
        mapProvider?.showUserLocation(true)
        
        // Start location updates
        startLocationUpdates()
        
        // Notify delegate
        delegate?.trackingDidStart(mode: trackingMode)
    }
    
    public func trackMarker(
        _ markerId: String,
        zoom: Double? = nil,
        mode: MarkerFollowMode = .northUp,
        pitch: Double = 0,
        followAnimationDuration: TimeInterval? = nil
    ) {
        let defaultZoomLevel = self.defaultZoomLevel
        Logging.l(tag: "LocationTracking", "Starting marker tracking for ID: \(markerId) with zoom: \(zoom ?? defaultZoomLevel), mode: \(mode)")

        guard mapProvider?.marker(byId: markerId) != nil else {
            let error = NSError(domain: "LocationTracking", code: 3, userInfo: [NSLocalizedDescriptionKey: "Marker with ID \(markerId) not found"])
            delegate?.trackingDidFail(error: error)
            return
        }

        trackingMode = .marker(id: markerId, zoom: zoom)
        trackingZoomLevel = zoom
        markerFollowMode = mode
        markerFollowPitch = pitch
        markerFollowAnimationDuration = followAnimationDuration
        isTrackingActive = true

        // Initial camera update (snaps for course-up, eases for north-up)
        updateCameraForMarker(markerId)

        // Notify delegate
        delegate?.trackingDidStart(mode: trackingMode)
    }
    
    public func stopTracking() {
        Logging.l(tag: "LocationTracking", "Stopping all tracking")
        
        trackingMode = .none
        trackingZoomLevel = nil
        markerFollowMode = .northUp
        markerFollowPitch = 0
        markerFollowAnimationDuration = nil
        isTrackingActive = false

        // Stop location updates
        stopLocationUpdates()
        
        // Notify delegate
        delegate?.trackingDidStop()
    }
    
    public func handleLocationUpdate(_ location: CLLocation) {
        self.currentLocation = location
        mapProvider?.updateUserLocation(location)
        
        if case .currentLocation = trackingMode {
            updateCameraForCurrentLocation(location)
        }
    }

    /// Throttles raw location-manager updates so the follow camera is not moved more
    /// often than necessary, then forwards to the canonical `handleLocationUpdate`.
    ///
    /// An update is applied when the throttle interval has elapsed, when this is the
    /// first fix, or when the device moved past `locationUpdateDistanceThreshold`.
    @MainActor
    func handleLocationUpdateThrottled(_ location: CLLocation) {
        let now = Date()
        let elapsed = lastThrottledLocationUpdate.map { now.timeIntervalSince($0) } ?? .greatestFiniteMagnitude
        let movedFarEnough = currentLocation.map {
            location.distance(from: $0) >= locationUpdateDistanceThreshold
        } ?? true

        guard elapsed >= locationUpdateThrottleInterval || movedFarEnough else { return }

        lastThrottledLocationUpdate = now
        handleLocationUpdate(location)
    }

    public func handleMarkerUpdate(_ marker: any UniversalMapMarkerProtocol) {
        if case .marker(let id, _) = trackingMode, id == marker.id {
            updateCameraForMarker(marker.id)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationTrackingManager: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Use throttled updates for smoother performance
        Task { @MainActor in
            handleLocationUpdateThrottled(location)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let clError = error as? CLError
        let errorMessage: String
        
        switch clError?.code {
        case .locationUnknown:
            errorMessage = "Location is currently unknown, but Core Location will keep trying"
            Logging.l(tag: "LocationTracking", "Location unknown, continuing to try...")
            // Don't stop tracking for this error, just log it
            return
        case .denied:
            errorMessage = "Location access denied. Please enable location access in Settings."
        case .network:
            errorMessage = "Network error occurred while getting location"
        case .headingFailure:
            errorMessage = "Heading could not be determined"
        case .regionMonitoringDenied:
            errorMessage = "Region monitoring access denied"
        case .regionMonitoringFailure:
            errorMessage = "Region monitoring failed"
        case .regionMonitoringSetupDelayed:
            errorMessage = "Region monitoring setup delayed"
        case .regionMonitoringResponseDelayed:
            errorMessage = "Region monitoring response delayed"
        case .geocodeFoundNoResult:
            errorMessage = "Geocode found no result"
        case .geocodeFoundPartialResult:
            errorMessage = "Geocode found partial result"
        case .geocodeCanceled:
            errorMessage = "Geocode was canceled"
        default:
            errorMessage = "Unknown location error: \(error.localizedDescription)"
        }
        
        Logging.l(tag: "LocationTracking", "Location manager failed with error: \(errorMessage)")
        
        // Create a more descriptive error
        let detailedError = NSError(
            domain: "LocationTracking",
            code: clError?.code.rawValue ?? -1,
            userInfo: [NSLocalizedDescriptionKey: errorMessage]
        )
        
        delegate?.trackingDidFail(error: detailedError)
        
        // Stop tracking for serious errors
        if let clError = clError, [.denied, .network].contains(clError.code) {
            stopTracking()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let authString = authorizationStatusString(status)
        Logging.l(tag: "LocationTracking", "Authorization status changed to: \(authString)")
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            Logging.l(tag: "LocationTracking", "Location authorized, checking if tracking should start...")
            if isTrackingActive && trackingMode != .none {
                Logging.l(tag: "LocationTracking", "Restarting location updates after authorization")
                locationManager.startUpdatingLocation()
            }
        case .denied, .restricted:
            Logging.l(tag: "LocationTracking", "Location access denied or restricted")
            let error = NSError(
                domain: "LocationTracking",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Location permission denied. Please enable location access in Settings."]
            )
            delegate?.trackingDidFail(error: error)
            stopTracking()
        case .notDetermined:
            Logging.l(tag: "LocationTracking", "Location authorization not determined")
            // Wait for user to respond to permission request
        @unknown default:
            Logging.l(tag: "LocationTracking", "Unknown authorization status: \(status.rawValue)")
            break
        }
    }
    
    private func authorizationStatusString(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .authorizedWhenInUse: return "Authorized When In Use"
        case .authorizedAlways: return "Authorized Always"
        @unknown default: return "Unknown (\(status.rawValue))"
        }
    }
}
