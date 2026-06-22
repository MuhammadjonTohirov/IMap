// Sources/MapPack/Models/LocationTracking/LocationTrackingManager.swift

import Foundation
import CoreLocation
import Combine

/// Centralized location update manager.
@MainActor
public final class LocationTrackingManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published public var currentLocation: CLLocation?
    @Published public private(set) var lastError: LocationTrackingError?
    
    // MARK: - Private Properties
    private let locationManager: any CoreLocationManaging
    private(set) weak var mapProvider: MapProviderProtocol?

    // MARK: - Location Update Throttling
    /// Timestamp of the last applied location update; drives time-based throttling.
    private var lastThrottledLocationUpdate: Date?
    /// Minimum interval between throttled location updates.
    private let locationUpdateThrottleInterval: TimeInterval = 0.5
    /// Distance (meters) that forces an immediate update regardless of the interval.
    private let locationUpdateDistanceThreshold: CLLocationDistance = 5

    private var isUserLocationDisplayActive: Bool = false
    private var isTrackingLocationUpdatesActive: Bool = false
    private var needsLocationUpdates: Bool {
        isUserLocationDisplayActive || isTrackingLocationUpdatesActive
    }

    // MARK: - Initialization
    public convenience override init() {
        self.init(locationManager: CLLocationManager())
    }

    init(locationManager: any CoreLocationManaging) {
        self.locationManager = locationManager
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Public Methods
    
    /// Set the map provider to control
    public func setMapProvider(_ provider: MapProviderProtocol) {
        self.mapProvider = provider
    }

    public func setUserLocationDisplayEnabled(_ enabled: Bool) {
        isUserLocationDisplayActive = enabled
        updateLocationUpdatesState()
    }

    public func setTrackingLocationUpdatesEnabled(_ enabled: Bool) {
        isTrackingLocationUpdatesActive = enabled
        updateLocationUpdatesState()
    }
    
    // MARK: - Private Methods

    private func updateLocationUpdatesState() {
        if needsLocationUpdates {
            startLocationUpdates()
        } else {
            stopLocationUpdates()
        }
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // Update every 5 meters
    }
    
    private func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            Logging.l(tag: "LocationTracking", "Requesting location permission...")
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            handleLocationError(.permissionDenied)
            stopLocationUpdates()
        case .authorizedWhenInUse, .authorizedAlways:
            Logging.l(tag: "LocationTracking", "Location permission granted, starting updates...")
            lastError = nil
            locationManager.startUpdatingLocation()
        @unknown default:
            Logging.l(tag: "LocationTracking", "Unknown authorization status")
            break
        }
    }

    private func handleAuthorizationStatusChange(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            Logging.l(tag: "LocationTracking", "Location authorized, checking if tracking should start...")
            lastError = nil
            if needsLocationUpdates {
                Logging.l(tag: "LocationTracking", "Restarting location updates after authorization")
                locationManager.startUpdatingLocation()
            }
        case .denied, .restricted:
            handleLocationError(.permissionDenied)
            stopLocationUpdates()
        case .notDetermined:
            Logging.l(tag: "LocationTracking", "Location authorization not determined")
        @unknown default:
            Logging.l(tag: "LocationTracking", "Unknown authorization status: \(status.rawValue)")
            break
        }
    }
    
    private func startLocationUpdates() {
        requestLocationPermission()
    }
    
    private func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }

    private func handleLocationError(_ error: LocationTrackingError) {
        lastError = error
        Logging.l(tag: "LocationTracking", error.localizedDescription)
    }
}

private extension LocationTrackingManager {
    func handleLocationUpdate(_ location: CLLocation) {
        self.currentLocation = location
        lastError = nil
        mapProvider?.updateUserLocation(location)
    }

    /// Throttles raw location-manager updates so the map provider is not updated more
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
}

// MARK: - CLLocationManagerDelegate
extension LocationTrackingManager: @MainActor CLLocationManagerDelegate {
    
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
            // Core Location will keep trying for this transient error.
            return
        case .denied:
            errorMessage = "Location access denied or Location Services disabled. Please enable location access in Settings."
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
        
        handleLocationError(LocationTrackingError.make(from: error))
        
        // Stop updates for serious errors.
        if let clError = clError, [.denied, .network].contains(clError.code) {
            stopLocationUpdates()
        }
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        let authString = authorizationStatusString(status)
        Logging.l(tag: "LocationTracking", "Authorization status changed to: \(authString)")

        handleAuthorizationStatusChange(status)
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
