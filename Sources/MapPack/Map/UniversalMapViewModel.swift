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
    func mapDidLoaded(map: MapProviderProtocol)
}

// Default implementation
public extension UniversalMapViewModelDelegate {
    func mapDidStartDragging(map: MapProviderProtocol) {}
    func mapDidStartMoving(map: MapProviderProtocol) {}
    func mapDidEndDragging(map: MapProviderProtocol, at location: CLLocation) {}
    func mapDidTapMarker(map: MapProviderProtocol, id: String) -> Bool {false}
    func mapDidTap(map: MapProviderProtocol, at coordinate: CLLocationCoordinate2D) {}
    func mapDidLoaded(map: MapProviderProtocol) {}
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
    @Published public var showUserLocation: Bool = true
    @Published public var userTrackingMode: Bool = false
    @Published public var edgeInsets = UniversalMapEdgeInsets()
    @Published public var addressInfo: AddressInfo?
    
    public private(set) var hasAddressPicker: Bool = true
    public private(set) var hasAddressView: Bool = true
    
    public private(set) var defaultZoomLevel: Double = 17
    var pinViewBottomOffset: CGFloat {
        let sarea = UIApplication.shared.safeArea
        let bottomOffset = self.edgeInsets.insets.bottom - sarea.top
        
        return bottomOffset
    }
    
    public private(set) var config: any MapConfigProtocol
    
    public private(set) weak var delegate: UniversalMapViewModelDelegate?
    public private(set) var pinModel: PinViewModel = .init()
    // Private properties
    public private(set) var mapProviderInstance: MapProviderProtocol
    
    private var markersById: [String: any UniversalMapMarkerProtocol] {
        mapProviderInstance.markers
    }
    
    var polylines: [UniversalMapPolyline] {
        Array(polylinesById.values)
    }
    
    private var polylinesById: [String: UniversalMapPolyline] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var routeTracker: RouteTrackingManager?
    private var currentTrackedPolyline: UniversalMapPolyline?
    
    // MARK: - Initialization
    
    /// Initialize with a specific map provider
    public init(mapProvider: MapProvider, config: any MapConfigProtocol) {
        self.mapProvider = mapProvider
        self.mapProviderInstance = MapProviderFactory.createMapProvider(type: mapProvider)
        self.config = config
        
        self.set(config: config)

        // Set up delegation
        self.mapProviderInstance.setInteractionDelegate(self)
        

        // Initialize the map provider with initial configuration
        self.updateMapProviderConfiguration()
    }
    
    deinit {
        debugPrint("UniversalMapViewModel: Deinit")
    }
    
    public func set(config: any MapConfigProtocol) {
        self.config = config
        self.mapProviderInstance.setConfig(config.mapConfiguration)
    }
    
    @MainActor
    public func set(preferredRefreshRate: MapRefreshRate) {
        self.mapProviderInstance.set(preferredRefreshRate: preferredRefreshRate)
    }

    /// Change the map provider type
    public func setMapProvider(_ provider: MapProvider, config: (any MapConfigProtocol)?) {
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
        
        if let config {
            set(config: config)
        }
    }
    
    /// Update the camera position
    public func updateCamera(to camera: UniversalMapCamera) {
        self.camera = camera
        mapProviderInstance.updateCamera(to: camera)
    }
    
    /// Set the map style
    public func setMapStyle(_ style: any UniversalMapStyleProtocol, scheme: ColorScheme) {
        mapProviderInstance.setMapStyle(style, scheme: scheme)
    }
    
    /// Show or hide the user's location
    public func showUserLocation(_ show: Bool) {
        self.showUserLocation = show
        mapProviderInstance.showUserLocation(show)
    }
    
    public func showBuildings(_ show: Bool) {
        mapProviderInstance.showBuildings(show)
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
        mapProviderInstance.addPolyline(polyline)
        return polyline.id
    }
    
    /// Remove a polyline from the map
    public func removePolyline(withId id: String) {
        polylinesById.removeValue(forKey: id)
        mapProviderInstance.removePolyline(withId: id)
    }
    
    /// Update an existing polyline with a new polyline object
    public func updatePolyline(_ polyline: UniversalMapPolyline) {
        self.addPolyline(polyline)
    }
    
    /// Update an existing polyline's coordinates by its ID
    /// - Parameters:
    ///   - id: The ID of the polyline to update
    ///   - coordinates: The new list of coordinates
    public func updatePolyline(id: String, coordinates: [CLLocationCoordinate2D]) {
        guard var polyline = polylinesById[id] else { return }
        polyline.coordinates = coordinates
        self.addPolyline(polyline)
    }
    
    /// Remove all polylines from the map
    public func clearAllPolylines() {
        polylinesById.removeAll()
        mapProviderInstance.clearAllPolylines()
    }
    
    @MainActor
    public func set(disabled: Bool) {
        self.mapProviderInstance.set(disabled: disabled)
    }
    
    /// Focus the map on a specific coordinate
    @MainActor
    public func focusMap(on coordinate: CLLocationCoordinate2D, zoom: Double? = nil, animated: Bool = true) {
        mapProviderInstance.focusMap(on: coordinate, zoom: zoom ?? defaultZoomLevel, animated: animated)
    }
    
    /// Focus the map on a specific polyline
    @MainActor
    public func focusOnPolyline(id: String, padding: UIEdgeInsets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: Bool = true) {
        mapProviderInstance.focusOnPolyline(id: id, padding: padding, animated: animated)
    }
    
    @MainActor
    public func focusTo(coordinates: [CLLocationCoordinate2D], padding: CGFloat = 0, animated: Bool) {
        mapProviderInstance.focusOn(coordinates: coordinates, padding: padding, animated: animated)
    }
    
    @MainActor
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
    public func focusToCurrentLocation(animated: Bool = true) {
        guard let location = self.mapProviderInstance.currentLocation else { return }
        
        self.mapProviderInstance.focusMap(
            on: location.coordinate,
            zoom: defaultZoomLevel,
            animated: animated
        )
    }
    
    public func set(hasAddressPicker: Bool) {
        self.hasAddressPicker = hasAddressPicker
    }
    
    public func set(hasAddressView: Bool) {
        self.hasAddressView = hasAddressView
    }
    
    @MainActor
    public func set(addressViewInfo: AddressInfo?) {
        self.addressInfo = addressViewInfo
    }
    
    @MainActor
    public func set(polylines: [UniversalMapPolyline]) {
        polylines.forEach { line in
            self.mapProviderInstance.addPolyline(line)
        }
    }
    
    @MainActor
    public func setOrUpdate(polylines: [UniversalMapPolyline]) {
        let newIds = Set(polylines.map { $0.id })
        
        // Identify IDs to remove (present in current but not in new)
        let idsToRemove = polylinesById.keys.filter { !newIds.contains($0) }
        
        idsToRemove.forEach { removePolyline(withId: $0) }
        
        // Add or update (addPolyline handles upsert)
        polylines.forEach { addPolyline($0) }
    }
    
    @MainActor
    public func set(userLocationIcon: UIImage, scale: CGFloat = 1.0) {
        mapProviderInstance.setUserLocationIcon(userLocationIcon, scale: scale)
    }
    
    @MainActor
    public func showUserLocationAccuracy(_ show: Bool) {
        mapProviderInstance.showUserLocationAccuracy(show)
    }
    
    @MainActor
    public func zoomOut(minLevel: Float = 10, shift: Double = 0.5) {
        mapProviderInstance.zoomOut(minLevel: minLevel, shift: shift)
    }
    
    // MARK: - Route Tracking
    
    /// Starts tracking a driver along the provided route.
    /// This initializes the tracking manager with the full polyline.
    public func startTracking(route: UniversalMapPolyline) {
        self.currentTrackedPolyline = route
        self.routeTracker = RouteTrackingManager(routeCoordinates: route.coordinates)
        // Ensure the route is visible on the map
        self.addPolyline(route)
    }
    
    // MARK: - Private Methods
    
    /// Update the map provider with all current configuration
    private func updateMapProviderConfiguration() {
        // Apply the current configuration
        if let camera = camera {
            mapProviderInstance.updateCamera(to: camera)
        }
        
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
        self.addressInfo = nil
        self.delegate?.mapDidStartDragging(map: self.mapProviderInstance)
    }
    
    public func mapDidStartMoving() {
        self.addressInfo = nil
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
    
    public func mapDidLoaded() {
        self.delegate?.mapDidLoaded(map: self.mapProviderInstance)
    }
}
