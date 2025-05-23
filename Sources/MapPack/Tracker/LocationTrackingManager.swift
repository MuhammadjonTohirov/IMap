// Sources/MapPack/Models/LocationTracking/LocationTrackingManager.swift

import Foundation
import CoreLocation
import Combine
import SwiftUI

/// Centralized location tracking manager
public class LocationTrackingManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published public private(set) var trackingMode: MapTrackingMode = .none
    @Published public private(set) var currentLocation: CLLocation?
    @Published public private(set) var isTrackingActive: Bool = false
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    private weak var mapProvider: MapProviderProtocol?
    private weak var delegate: LocationTrackingDelegate?
    
    private var defaultZoomLevel: Double = 17
    private var trackingZoomLevel: Double?
    
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
            
            Task {@MainActor in
                requestLocationPermission()
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
        
        UIView.animate(withDuration: 0.3) {
            
            self.mapProvider?.updateCamera(to: camera)
        }
    }
    
    private func updateCameraForMarker(_ markerId: String) {
        guard case .marker(let id, let zoom) = trackingMode,
              id == markerId,
              let marker = mapProvider?.marker(byId: markerId) else { return }
        
        let targetZoom = zoom ?? trackingZoomLevel ?? defaultZoomLevel
        let camera = UniversalMapCamera(
            center: marker.coordinate,
            zoom: targetZoom,
            animate: true
        )
        
        mapProvider?.updateCamera(to: camera)
    }
}

// MARK: - LocationTrackingProtocol Implementation
extension LocationTrackingManager: LocationTrackingProtocol {
    
    public func trackCurrentLocationOnMap(zoom: Double? = nil) {
        Logging.l(tag: "LocationTracking", "Starting current location tracking with zoom: \(zoom ?? self.defaultZoomLevel)")
        
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
    
    public func trackMarker(_ markerId: String, zoom: Double? = nil) {
        Logging.l(tag: "LocationTracking", "Starting marker tracking for ID: \(markerId) with zoom: \(zoom ?? self.defaultZoomLevel)")
        
        guard mapProvider?.marker(byId: markerId) != nil else {
            let error = NSError(domain: "LocationTracking", code: 3, userInfo: [NSLocalizedDescriptionKey: "Marker with ID \(markerId) not found"])
            delegate?.trackingDidFail(error: error)
            return
        }
        
        trackingMode = .marker(id: markerId, zoom: zoom)
        trackingZoomLevel = zoom
        isTrackingActive = true
        
        // Initial camera update
        updateCameraForMarker(markerId)
        
        // Notify delegate
        delegate?.trackingDidStart(mode: trackingMode)
    }
    
    public func stopTracking() {
        Logging.l(tag: "LocationTracking", "Stopping all tracking")
        
        trackingMode = .none
        trackingZoomLevel = nil
        isTrackingActive = false
        
        // Stop location updates
        stopLocationUpdates()
        
        // Notify delegate
        delegate?.trackingDidStop()
    }
    
    public func handleLocationUpdate(_ location: CLLocation) {
        self.currentLocation = location
        
        if case .currentLocation = trackingMode {
            updateCameraForCurrentLocation(location)
        }
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
        handleLocationUpdate(location)
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
        Logging.l(tag: "LocationTracking", "Authorization status changed to: \(self.authorizationStatusString(status))")
        
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
