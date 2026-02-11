//
//  RouteSessionManager.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

import Foundation
import CoreLocation

/// Manages the state of an active route session
public class RouteSessionManager: ObservableObject {
    @Published public private(set) var currentTrackedPolyline: UniversalMapPolyline?
    
    private var routeTracker: RouteTrackingManager?
    private weak var mapProvider: MapPolylineManageable?
    
    public init() {}
    
    public func setMapProvider(_ provider: MapPolylineManageable) {
        self.mapProvider = provider
    }
    
    /// Starts tracking a driver along the provided route.
    /// This initializes the tracking manager with the full polyline.
    public func startTracking(route: UniversalMapPolyline) {
        self.currentTrackedPolyline = route
        self.routeTracker = RouteTrackingManager(routeCoordinates: route.coordinates)
        // Ensure the route is visible on the map
        self.mapProvider?.addPolyline(route, animated: false)
    }
    
    public func updateDriverLocation(_ location: CLLocationCoordinate2D) -> RouteTrackingStatus? {
        return routeTracker?.updateDriverLocation(location)
    }
    
    public func stopTracking() {
        self.currentTrackedPolyline = nil
        self.routeTracker = nil
    }
}
