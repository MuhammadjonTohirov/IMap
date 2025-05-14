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

public protocol UniversalMapViewModelDelegate: AnyObject {
    func mapDidStartDragging(map: MapProviderProtocol)
    func mapDidStartMoving(map: MapProviderProtocol)
    func mapDidEndDragging(map: MapProviderProtocol, at location: CLLocation)
    func mapDidTapMarker(map: MapProviderProtocol, id: String) -> Bool
    func mapDidTap(map: MapProviderProtocol, at coordinate: CLLocationCoordinate2D)
}

// Default implementation
public extension UniversalMapViewModelDelegate {
    func mapDidStartDragging(map: MapProviderProtocol) {}
    func mapDidStartMoving(map: MapProviderProtocol) {}
    func mapDidEndDragging(map: MapProviderProtocol, at location: CLLocation) {}
    func mapDidTapMarker(map: MapProviderProtocol, id: String) -> Bool {false}
    func mapDidTap(map: MapProviderProtocol, at coordinate: CLLocationCoordinate2D) {}
}

public struct AddressInfo {
    public var name: String?
    public var location: CLLocationCoordinate2D?
    
    public init(name: String? = nil, location: CLLocationCoordinate2D? = nil) {
        self.name = name
        self.location = location
    }
}

/// View model for the Universal Map
public class UniversalMapViewModel: ObservableObject {
    // Published properties
    @Published public var mapProvider: MapProvider
    @Published public var camera: UniversalMapCamera?
    @Published public var mapStyle: UniversalMapStyle = .light
    @Published public var showUserLocation: Bool = true
    @Published public var userTrackingMode: Bool = false
    @Published public var polylines: [UniversalMapPolyline] = []
    @Published public var edgeInsets = UniversalMapEdgeInsets()
    @Published public var addressInfo: AddressInfo?
    
    public private(set) var hasAddressPicker: Bool = true
    public private(set) var hasAddressView: Bool = true
    
    public private(set) var defaultZoomLevel: Double = 15
    var pinViewBottomOffset: CGFloat {
        let bottomOffset = self.edgeInsets.insets.bottom
        
        return bottomOffset
    }
    public private(set) weak var delegate: UniversalMapViewModelDelegate?
    public private(set) var pinModel: PinViewModel = .init()
    // Private properties
    public private(set) var mapProviderInstance: MapProviderProtocol
    private var markersById: [String: any UniversalMapMarkerProtocol] {
        mapProviderInstance.markers
    }
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
    public func addMarker(_ marker: any UniversalMapMarkerProtocol) -> String {
        mapProviderInstance.addMarker(marker)
        return marker.id
    }
    
    public func marker(byId id: String) -> (any UniversalMapMarkerProtocol)? {
        return markersById[id]
    }
    
    public func updateMarker(_ marker: any UniversalMapMarkerProtocol) {
        mapProviderInstance.updateMarker(marker)
    }
    
    /// Remove a marker from the map
    public func removeMarker(withId id: String) {
        mapProviderInstance.removeMarker(withId: id)
    }
    
    /// Remove all markers from the map
    public func clearAllMarkers() {
        mapProviderInstance.clearAllMarkers()
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
    
    public func focusTo(coordinates: [CLLocationCoordinate2D], padding: CGFloat = 0, animated: Bool) {
        mapProviderInstance.focusOn(coordinates: coordinates, padding: padding, animated: animated)
    }
    
    public func focusTo(coordinates: [CLLocationCoordinate2D], edge: UIEdgeInsets, animated: Bool) {
        mapProviderInstance.focusOn(coordinates: coordinates, edges: edge, animated: animated)
    }
    
    /// Get the current map view
    public func makeMapView() -> AnyView {
        return mapProviderInstance.makeMapView()
    }
    
    public func setInteractionDelegate(_ delegate: any UniversalMapViewModelDelegate) {
        self.delegate = delegate
    }
    
    @MainActor
    public func focusToCurrentLocation() {
        guard let location = self.mapProviderInstance.currentLocation else { return }
        
        self.mapProviderInstance.focusMap(
            on: location.coordinate,
            zoom: defaultZoomLevel
        )
    }
    
    public func set(hasAddressPicker: Bool) {
        self.hasAddressPicker = hasAddressPicker
    }
    
    public func set(hasAddressView: Bool) {
        self.hasAddressView = hasAddressView
    }
    
    @MainActor
    public func set(polylines: [UniversalMapPolyline]) {
        self.polylines = polylines
        self.polylines.forEach { line in
            self.mapProviderInstance.addPolyline(line)
        }
    }
    
    @MainActor
    public func clearRouteData() {
        polylines.forEach {
            self.mapProviderInstance.removePolyline(withId: $0.id)
        }
        polylines.removeAll()
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
        for marker in markersById.values {
            mapProviderInstance.updateMarker(marker)
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
        self.delegate?.mapDidStartMoving(map: self.mapProviderInstance)
    }
    
    public func mapDidStartMoving() {
        self.delegate?.mapDidStartMoving(map: self.mapProviderInstance)
    }
    
    public func mapDidEndDragging(at location: CLLocation) {
        self.delegate?.mapDidEndDragging(map: self.mapProviderInstance, at: location)
    }
    
    public func mapDidTapMarker(id: String) -> Bool {
        self.delegate?.mapDidTapMarker(map: self.mapProviderInstance, id: id) ?? false
    }
    
    public func mapDidTap(at coordinate: CLLocationCoordinate2D) {
        self.delegate?.mapDidTap(map: self.mapProviderInstance, at: coordinate)
    }
}
