//
//  UniversalMapViewModel.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

// UniversalMap/UniversalMapViewModel.swift
import Foundation
import SwiftUI
import CoreLocation
import Combine

/// View model for the Universal Map
public class UniversalMapViewModel: ObservableObject {
    // Published properties
    @Published public var mapProvider: MapProvider
    @Published public var camera: UniversalMapCamera?
    @Published public var mapStyle: UniversalMapStyle = .light
    @Published public var showUserLocation: Bool = true
    @Published public var userTrackingMode: Bool = false
    @Published public var markers: [UniversalMapMarker] = []
    @Published public var polylines: [UniversalMapPolyline] = []
    @Published public var edgeInsets = UniversalMapEdgeInsets()
    
    var pinViewBottomOffset: CGFloat {
        self.edgeInsets.insets.bottom
    }
    
    public private(set) var pinModel: PinViewModel = .init()
    // Private properties
    public private(set) var mapProviderInstance: MapProviderProtocol
    private var markersById: [String: UniversalMapMarker] = [:]
    private var polylinesById: [String: UniversalMapPolyline] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initialize with a specific map provider
    public init(mapProvider: MapProvider, input: (any UniversalMapInputProvider)?) {
        self.mapProvider = mapProvider
        self.mapProviderInstance = MapProviderFactory.createMapProvider(type: mapProvider)
        
        // Set up delegation
        self.mapProviderInstance.setInteractionDelegate(self)
        
        // Initialize the map provider with initial configuration
        self.updateMapProviderConfiguration()
        
        if let input { self.set(input: input) }
    }
    
    public func set(input: any UniversalMapInputProvider) {
        mapProviderInstance.setInput(input: input)
    }
    
    // MARK: - Public Methods
    
    /// Change the map provider type
    public func setMapProvider(_ provider: MapProvider, input: (any UniversalMapInputProvider)?) {
        // Only change if different
        guard provider != mapProvider else { return }
        
        // Update the provider type
        mapProvider = provider
        
        // Create new provider instance
        mapProviderInstance = MapProviderFactory.createMapProvider(type: provider)
        
        // Set delegation
        mapProviderInstance.setInteractionDelegate(self)
        
        // Reapply current configuration to the new provider
        updateMapProviderConfiguration()
        
        if let input { self.set(input: input) }
    }
    
    /// Update the camera position
    public func updateCamera(to camera: UniversalMapCamera) {
        self.camera = camera
        mapProviderInstance.updateCamera(to: camera)
    }
    
    /// Set the map style
    public func setMapStyle(_ style: UniversalMapStyle) {
        self.mapStyle = style
        mapProviderInstance.setMapStyle(style)
    }
    
    /// Show or hide the user's location
    public func showUserLocation(_ show: Bool) {
        self.showUserLocation = show
        mapProviderInstance.showUserLocation(show)
    }
    
    /// Enable or disable user tracking mode
    public func setUserTrackingMode(_ tracking: Bool) {
        self.userTrackingMode = tracking
        mapProviderInstance.setUserTrackingMode(tracking)
    }
    
    /// Set the map edge insets
    public func setEdgeInsets(_ insets: UniversalMapEdgeInsets) {
        self.edgeInsets = insets
        mapProviderInstance.setEdgeInsets(insets)
    }
    
    /// Add a marker to the map
    @discardableResult
    public func addMarker(_ marker: UniversalMapMarker) -> String {
        markersById[marker.id] = marker
        markers.append(marker)
        mapProviderInstance.addMarker(marker)
        return marker.id
    }
    
    /// Remove a marker from the map
    public func removeMarker(withId id: String) {
        if let index = markers.firstIndex(where: { $0.id == id }) {
            markers.remove(at: index)
        }
        markersById.removeValue(forKey: id)
        mapProviderInstance.removeMarker(withId: id)
    }
    
    /// Remove all markers from the map
    public func clearAllMarkers() {
        mapProviderInstance.clearAllMarkers()
        markers.removeAll()
        markersById.removeAll()
    }
    
    /// Add a polyline to the map
    @discardableResult
    public func addPolyline(_ polyline: UniversalMapPolyline) -> String {
        polylinesById[polyline.id] = polyline
        polylines.append(polyline)
        mapProviderInstance.addPolyline(polyline)
        return polyline.id
    }
    
    /// Remove a polyline from the map
    public func removePolyline(withId id: String) {
        if let index = polylines.firstIndex(where: { $0.id == id }) {
            polylines.remove(at: index)
        }
        polylinesById.removeValue(forKey: id)
        mapProviderInstance.removePolyline(withId: id)
    }
    
    /// Remove all polylines from the map
    public func clearAllPolylines() {
        polylines.removeAll()
        polylinesById.removeAll()
        mapProviderInstance.clearAllPolylines()
    }
    
    /// Focus the map on a specific coordinate
    public func focusMap(on coordinate: CLLocationCoordinate2D, zoom: Double? = nil) {
        mapProviderInstance.focusMap(on: coordinate, zoom: zoom)
    }
    
    /// Focus the map on a specific polyline
    public func focusOnPolyline(id: String, padding: UIEdgeInsets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: Bool = true) {
        mapProviderInstance.focusOnPolyline(id: id, padding: padding, animated: animated)
    }
    
    /// Get the current map view
    public func makeMapView() -> AnyView {
        return mapProviderInstance.makeMapView()
    }
    
    public func setInteractionDelegate(_ delegate: any MapInteractionDelegate) {
        self.mapProviderInstance.setInteractionDelegate(delegate)
    }
    
    // MARK: - Private Methods
    
    /// Update the map provider with all current configuration
    private func updateMapProviderConfiguration() {
        // Apply the current configuration
        if let camera = camera {
            mapProviderInstance.updateCamera(to: camera)
        }
        
        mapProviderInstance.setMapStyle(mapStyle)
        mapProviderInstance.showUserLocation(showUserLocation)
        mapProviderInstance.setUserTrackingMode(userTrackingMode)
        mapProviderInstance.setEdgeInsets(edgeInsets)
        
        // Re-add all markers
        for marker in markers {
            mapProviderInstance.addMarker(marker)
        }
        
        // Re-add all polylines
        for polyline in polylines {
            mapProviderInstance.addPolyline(polyline)
        }
    }
}

// MARK: - MapInteractionDelegate Implementation
extension UniversalMapViewModel: MapInteractionDelegate {
    public func mapDidStartDragging() {
        // Implement any view model logic when map dragging starts
    }
    
    public func mapDidStartMoving() {
        // Implement any view model logic when map movement starts
    }
    
    public func mapDidEndDragging(at location: CLLocation) {
        // Implement any view model logic when map dragging ends
    }
    
    public func mapDidTapMarker(id: String) -> Bool {
        // Return true if you've handled the tap, false to show the default info window
        return false
    }
    
    public func mapDidTap(at coordinate: CLLocationCoordinate2D) {
        // Handle map tap events
    }
}
