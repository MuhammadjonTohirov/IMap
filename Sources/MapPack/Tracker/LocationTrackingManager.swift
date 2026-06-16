// Sources/MapPack/Models/LocationTracking/LocationTrackingManager.swift

import Foundation
import CoreLocation
import Combine
import NavigationTrackingCore

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

    // MARK: - Follow Configuration (current-location and marker)
    private(set) var followOrientation: CameraFollowMode = .northUp
    private(set) var followPitch: Double = 0
    private(set) var followAnimationDuration: TimeInterval?
    /// Last reliable course (degrees) used for course-up current-location following;
    /// held when the device is too slow for `CLLocation.course` to be trustworthy.
    private var lastCourseUpBearing: CLLocationDirection?
    /// Speed (m/s) below which `CLLocation.course` is treated as unreliable.
    private let minReliableCourseSpeed: CLLocationSpeed = 1.5
    /// Recent positions used to derive a stable movement bearing when GPS course is
    /// unavailable (e.g. on the simulator or at low speed).
    private var followCoordinateTrail: [CLLocationCoordinate2D] = []
    /// Number of recent positions retained for the movement-bearing trail.
    private let followTrailLimit = 4
    /// Minimum trail span (meters) before a movement bearing is considered meaningful.
    private let minTrailBearingDistance: CLLocationDistance = 1.0

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
        updateFollowCamera(
            coordinate: location.coordinate,
            heading: courseUpBearing(for: location),
            zoom: targetZoom
        )
    }
    
    private func updateCameraForMarker(_ markerId: String) {
        guard case .marker(let id, let zoom) = trackingMode,
              id == markerId,
              let marker = mapProvider?.marker(byId: markerId) else { return }

        let targetZoom = zoom ?? trackingZoomLevel ?? defaultZoomLevel
        updateFollowCamera(
            coordinate: marker.coordinate,
            heading: marker.worldHeading,
            zoom: targetZoom
        )
    }

    /// Builds and applies the follow camera shared by current-location and marker
    /// following. Course-up snaps to the heading so the map reacts instantly; north-up
    /// eases toward the target, which also animates the bearing back to north when
    /// leaving course-up.
    private func updateFollowCamera(
        coordinate: CLLocationCoordinate2D,
        heading: CLLocationDirection,
        zoom: Double
    ) {
        let isCourseUp = followOrientation == .courseUp
        let camera = UniversalMapCamera(
            center: coordinate,
            zoom: zoom,
            bearing: isCourseUp ? heading : 0,
            pitch: followPitch,
            animate: !isCourseUp,
            animationDuration: isCourseUp ? nil : followAnimationDuration
        )
        mapProvider?.updateCamera(to: camera)
    }

    /// Heading for course-up current-location following.
    ///
    /// Prefers GPS `course` when the device is clearly moving (Core Location already
    /// smooths it); otherwise derives the bearing from a short trail of recent positions
    /// (oldest → newest). The trail both works when `course` is unavailable (simulator,
    /// low speed) and averages out per-fix jitter. The last bearing is held when neither
    /// source is usable, so the map never spins while stationary.
    private func courseUpBearing(for location: CLLocation) -> CLLocationDirection {
        let coordinate = location.coordinate

        // Append to the trail, ignoring near-duplicate fixes.
        let movedEnough = followCoordinateTrail.last.map {
            $0.greatCircleDistance(to: coordinate) > 0.5
        } ?? true
        if movedEnough {
            followCoordinateTrail.append(coordinate)
            if followCoordinateTrail.count > followTrailLimit {
                followCoordinateTrail.removeFirst()
            }
        }

        if location.course >= 0, location.speed >= minReliableCourseSpeed {
            lastCourseUpBearing = location.course
        } else if let oldest = followCoordinateTrail.first,
                  oldest.greatCircleDistance(to: coordinate) > minTrailBearingDistance,
                  let bearing = oldest.bearing(to: coordinate) {
            lastCourseUpBearing = bearing
        }

        return lastCourseUpBearing ?? 0
    }
}

// MARK: - LocationTrackingProtocol Implementation
extension LocationTrackingManager: LocationTrackingProtocol {
    
    public func trackCurrentLocationOnMap(
        zoom: Double? = nil,
        mode: CameraFollowMode = .northUp,
        pitch: Double = 0,
        followAnimationDuration: TimeInterval? = nil
    ) {
        let defaultZoomLevel = self.defaultZoomLevel
        Logging.l(tag: "LocationTracking", "Starting current location tracking with zoom: \(zoom ?? defaultZoomLevel), mode: \(mode)")

        // One camera owner: drop any native follow before taking over.
        mapProvider?.setUserTrackingMode(false)

        trackingMode = .currentLocation(zoom: zoom)
        trackingZoomLevel = zoom
        followOrientation = mode
        followPitch = pitch
        self.followAnimationDuration = followAnimationDuration
        lastCourseUpBearing = nil
        followCoordinateTrail.removeAll()
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
        mode: CameraFollowMode = .northUp,
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

        // One camera owner: drop any native follow before taking over.
        mapProvider?.setUserTrackingMode(false)

        trackingMode = .marker(id: markerId, zoom: zoom)
        trackingZoomLevel = zoom
        followOrientation = mode
        followPitch = pitch
        self.followAnimationDuration = followAnimationDuration
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
        followOrientation = .northUp
        followPitch = 0
        followAnimationDuration = nil
        lastCourseUpBearing = nil
        followCoordinateTrail.removeAll()
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
