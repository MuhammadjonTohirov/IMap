//
//  File.swift
//  IMap
//
//  Created by applebro on 23/05/25.
//
// Sources/MapPack/Map/UniversalMapViewModel+LocationTracking.swift

import Foundation
import CoreLocation
import Combine

// MARK: - UniversalMapViewModel Location Tracking Extension
public extension UniversalMapViewModel {
    
    /// Location tracking manager
    var locationTrackingManager: LocationTrackingManager {
        // Store as associated object to maintain single instance
        if let manager = objc_getAssociatedObject(self, &AssociatedKeys.locationTrackingManager) as? LocationTrackingManager {
            return manager
        }
        
        let manager = LocationTrackingManager()
        manager.setMapProvider(mapProviderInstance)
        manager.setDelegate(self)
        manager.setDefaultZoomLevel(defaultZoomLevel)
        
        objc_setAssociatedObject(self, &AssociatedKeys.locationTrackingManager, manager, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return manager
    }
    
    /// Current tracking mode
    var trackingMode: MapTrackingMode {
        locationTrackingManager.trackingMode
    }
    
    /// Whether location tracking is active
    var isLocationTrackingActive: Bool {
        locationTrackingManager.isTrackingActive
    }
    
    /// Current tracked location
    var trackedLocation: CLLocation? {
        locationTrackingManager.currentLocation
    }
    
    /// Start tracking current location with camera following
    /// - Parameter zoom: Optional zoom level (uses default if nil)
    @MainActor
    func trackCurrentLocationOnMap(zoom: Double? = nil) {
        locationTrackingManager.trackCurrentLocationOnMap(zoom: zoom)
    }
    
    /// Start tracking a specific marker with camera following
    /// - Parameters:
    ///   - markerId: ID of the marker to track
    ///   - zoom: Optional zoom level (uses default if nil)
    func trackMarker(_ markerId: String, zoom: Double? = nil) {
        locationTrackingManager.trackMarker(markerId, zoom: zoom)
    }
    
    /// Stop all location and marker tracking
    func stopTracking() {
        locationTrackingManager.stopTracking()
    }
    
    /// Update tracking manager when map provider changes
    internal func updateLocationTrackingProvider() {
        locationTrackingManager.setMapProvider(mapProviderInstance)
        locationTrackingManager.setDefaultZoomLevel(defaultZoomLevel)
    }
    
    /// Notify tracking manager when markers are updated
    internal func notifyMarkerUpdate(_ marker: any UniversalMapMarkerProtocol) {
        locationTrackingManager.handleMarkerUpdate(marker)
    }
}

// MARK: - LocationTrackingDelegate Implementation
extension UniversalMapViewModel: LocationTrackingDelegate {
    
    public func trackingDidStart(mode: MapTrackingMode) {
        Logging.l(tag: "UniversalMap", "Location tracking started: \(mode)")
        
        // Update UI or notify delegates if needed
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    public func trackingDidStop() {
        Logging.l(tag: "UniversalMap", "Location tracking stopped")
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    public func trackingDidFail(error: Error) {
        Logging.l(tag: "UniversalMap", "Location tracking failed: \(error.localizedDescription)")
        
        // Handle error - could show alert, update UI, etc.
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}

// MARK: - Override existing methods to support tracking
public extension UniversalMapViewModel {
    
    /// Enhanced addMarker that notifies tracking manager
    @discardableResult
    func addMarkerWithTracking(_ marker: any UniversalMapMarkerProtocol) -> String {
        let markerId = addMarker(marker)
        notifyMarkerUpdate(marker)
        return markerId
    }
    
    /// Enhanced updateMarker that notifies tracking manager
    func updateMarkerWithTracking(_ marker: any UniversalMapMarkerProtocol) {
        updateMarker(marker)
        notifyMarkerUpdate(marker)
    }
    
    /// Enhanced setMapProvider that updates tracking
    func setMapProviderWithTracking(_ provider: MapProvider, input: any MapConfigProtocol) {
        setMapProvider(provider, config: input)
        updateLocationTrackingProvider()
    }
}

// MARK: - Associated Keys for objc_setAssociatedObject
private struct AssociatedKeys {
    static var locationTrackingManager = "locationTrackingManager"
}
