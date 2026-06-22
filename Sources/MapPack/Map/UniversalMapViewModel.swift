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
import UIKit

@MainActor
public protocol UniversalMapViewModelDelegate: AnyObject {
    func mapDidStartDragging(map: MapProviderProtocol)
    func mapDidStartMoving(map: MapProviderProtocol)
    func mapDidEndDragging(map: MapProviderProtocol, at location: CLLocation)
    func mapDidTapMarker(map: MapProviderProtocol, id: String) -> Bool
    func mapDidTap(map: MapProviderProtocol, at coordinate: CLLocationCoordinate2D)
    func mapDidLoaded(map: MapProviderProtocol)
    func mapDidRotate(map: MapProviderProtocol, location: CLLocationCoordinate2D)
    func mapDidChangeUserTrackingMode(
        map: MapProviderProtocol,
        mode: UserLocationtrackingMode,
        reason: UserTrackingModeChangeReason
    )
}

// Default implementation
public extension UniversalMapViewModelDelegate {
    func mapDidStartDragging(map: MapProviderProtocol) {}
    func mapDidStartMoving(map: MapProviderProtocol) {}
    func mapDidEndDragging(map: MapProviderProtocol, at location: CLLocation) {}
    func mapDidTapMarker(map: MapProviderProtocol, id: String) -> Bool {false}
    func mapDidTap(map: MapProviderProtocol, at coordinate: CLLocationCoordinate2D) {}
    func mapDidLoaded(map: MapProviderProtocol) {}
    func mapDidRotate(map: MapProviderProtocol, location: CLLocationCoordinate2D) {}
    func mapDidChangeUserTrackingMode(
        map: MapProviderProtocol,
        mode: UserLocationtrackingMode,
        reason: UserTrackingModeChangeReason
    ) {}
}

public struct AddressInfo: Sendable {
    public var name: String?
    public var location: CLLocationCoordinate2D?
    
    public init(name: String? = nil, location: CLLocationCoordinate2D? = nil) {
        self.name = name
        self.location = location
    }
}

/// View model for the Universal Map
@MainActor
public class UniversalMapViewModel: ObservableObject {
    // MARK: - Components
    @Published public var uiState = MapUIState()
    public let locationTrackingManager: LocationTrackingManager
    private let deviceHeadingProvider: any DeviceHeadingProviding

    // MARK: - Published Properties (Backward Compatibility / Facade)
    @Published public var mapProvider: MapProvider
    @Published var camera: UniversalMapCamera?
    
    public var showUserLocation: Bool {
        get { uiState.showUserLocation }
        set {
            uiState.showUserLocation = newValue
            mapProviderInstance.showUserLocation(newValue)
            locationTrackingManager.setUserLocationDisplayEnabled(newValue)
        }
    }
    
    public var userTrackingMode: UserLocationtrackingMode {
        get { uiState.userTrackingMode }
        set {
            _ = applyUserTrackingMode(newValue, reason: .programmatic)
        }
    }
    
    public var edgeInsets: UniversalMapEdgeInsets {
        get { uiState.edgeInsets }
        set {
            uiState.edgeInsets = newValue
            mapProviderInstance.setEdgeInsets(newValue)
        }
    }
    
    public var addressInfo: AddressInfo? {
        get { uiState.addressInfo }
        set { uiState.addressInfo = newValue }
    }
    
    public var hasAddressPicker: Bool {
        uiState.hasAddressPicker
    }
    
    public var hasAddressView: Bool {
        uiState.hasAddressView
    }
    
    public var pinViewBottomOffset: CGFloat {
        uiState.pinViewBottomOffset
    }
    
    public var pinModel: PinViewModel {
        uiState.pinModel
    }
    
    public private(set) var defaultZoomLevel: Double = 17
    public private(set) var config: any MapConfigProtocol
    public private(set) weak var delegate: UniversalMapViewModelDelegate?
    
    // Private properties
    public private(set) var mapProviderInstance: MapProviderProtocol
    
    private var markersById: [String: any UniversalMapMarkerProtocol] = [:]
    private var tintColor: UIColor?
    private var cancellables = Set<AnyCancellable>()
    var latestDeviceHeading: DeviceHeading?
    
    var polylines: [UniversalMapPolyline] {
        Array(polylinesById.values)
    }
    
    private var polylinesById: [String: UniversalMapPolyline] = [:]
    
    // MARK: - Initialization
    
    /// Initialize with a specific map provider instance (Dependency Injection)
    public init(
        instance: MapProviderProtocol,
        providerType: MapProvider,
        config: any MapConfigProtocol,
        deviceHeadingProvider: (any DeviceHeadingProviding)? = nil,
        locationTrackingManager: LocationTrackingManager? = nil
    ) {
        self.mapProvider = providerType
        self.mapProviderInstance = instance
        self.config = config
        self.deviceHeadingProvider = deviceHeadingProvider ?? DeviceHeadingProvider()
        self.locationTrackingManager = locationTrackingManager ?? LocationTrackingManager()
        
        self.set(config: config)
        
        // Setup Managers
        self.locationTrackingManager.setMapProvider(instance)
        self.deviceHeadingProvider.delegate = self
        self.observeLocationUpdates()

        // Set up delegation
        self.mapProviderInstance.setInteractionDelegate(self)
        
        // Initialize the map provider with initial configuration
        self.updateMapProviderConfiguration()
    }

    /// Convenience initializer using the factory
    public convenience init(mapProvider: MapProvider, config: any MapConfigProtocol) {
        let instance = MapProviderFactory.createMapProvider(type: mapProvider)
        self.init(instance: instance, providerType: mapProvider, config: config)
    }
    
    deinit {
        Logging.l(tag: "UniversalMapViewModel", "Deinit")
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
        
        // Update Managers
        locationTrackingManager.setMapProvider(mapProviderInstance)

        // Set delegation
        mapProviderInstance.setInteractionDelegate(self)

        if let config {
            set(config: config)
        } else {
            set(config: self.config)
        }
        
        // Reapply current configuration to the new provider
        updateMapProviderConfiguration()
    }
    
    public func getCamera(animate: Bool = true) -> UniversalMapCamera? {
        switch mapProvider {
        case .google:
            if let cam = (self.mapProviderInstance as? GoogleMapsProvider)?.viewModel.mapView?.camera {
                return .init(
                    center: cam.target,
                    zoom: Double(cam.zoom),
                    bearing: cam.bearing,
                    pitch: cam.viewingAngle,
                    animate: animate
                )
            }
        case .mapLibre:
            if let mapView = (self.mapProviderInstance as? MapLibreProvider)?.viewModel.mapView {
                let cam = mapView.camera
                return .init(
                    center: cam.centerCoordinate,
                    zoom: mapView.zoomLevel,
                    bearing: mapView.direction,
                    pitch: cam.pitch,
                    animate: animate
                )
            }
        }
        
        return nil
    }
    
    /// Update the camera position
    public func updateCamera(to camera: UniversalMapCamera) {
        self.camera = camera
        mapProviderInstance.updateCamera(to: camera)
    }

    /// Rotate the map to `bearing`, leaving the center, zoom, and pitch unchanged.
    ///
    /// Sets the provider's native heading directly (no camera round-trip), so the
    /// visible zoom can't drift as a side effect of changing direction.
    ///
    /// - Parameters:
    ///   - bearing: Target heading in degrees clockwise from true north
    ///     (0 = north, 90 = east).
    ///   - animate: Animate the rotation. Defaults to `true`.
    public func setBearing(_ bearing: CLLocationDirection, animate: Bool = true) {
        switch mapProvider {
        case .google:
            (mapProviderInstance as? GoogleMapsProvider)?.setBearing(bearing, animate: animate)
        case .mapLibre:
            (mapProviderInstance as? MapLibreProvider)?.setBearing(bearing, animate: animate)
        }

        // Keep the cached camera's bearing coherent for internal observers.
        camera?.bearing = bearing
    }

    /// Set the map direction in degrees clockwise from true north.
    ///
    /// This is a MapLibre-friendly name for ``setBearing(_:animate:)``; both map
    /// providers use the same normalized world heading.
    public func setDirection(_ direction: CLLocationDirection, animated: Bool = true) {
        setBearing(direction, animate: animated)
    }
    
    /// Set the map style
    public func setMapStyle(_ style: any UniversalMapStyleProtocol, scheme: ColorScheme) {
        mapProviderInstance.setMapStyle(style, scheme: scheme)
    }

    /// Set the native map view tint color.
    @MainActor
    public func setTintColor(_ color: UIColor) {
        tintColor = color
        mapProviderInstance.setTintColor(color)
    }
    
    /// Show or hide the user's location
    public func showUserLocation(_ show: Bool) {
        self.showUserLocation = show // Goes through setter updating uiState and provider
    }
    
    public func showBuildings(_ show: Bool) {
        mapProviderInstance.showBuildings(show)
    }
    
    /// Enable or disable user tracking mode
    @discardableResult
    public func setUserTrackingMode(_ mode: UserLocationtrackingMode) -> Bool {
        applyUserTrackingMode(mode, reason: .programmatic)
    }
    
    /// Set the map edge insets
    public func setEdgeInsets(_ insets: UniversalMapEdgeInsets) {
        self.edgeInsets = insets // Goes through setter
    }
    
    /// Add a marker to the map
    @discardableResult
    public func addMarker(_ marker: any UniversalMapMarkerProtocol) -> String {
        markersById[marker.id] = marker
        mapProviderInstance.addMarker(marker)
        return marker.id
    }
    
    public func marker(byId id: String) -> (any UniversalMapMarkerProtocol)? {
        return markersById[id]
    }
    
    public func updateMarker(_ marker: any UniversalMapMarkerProtocol) {
        let didAlreadyKnowMarker = markersById[marker.id] != nil
        markersById[marker.id] = marker

        if didAlreadyKnowMarker {
            mapProviderInstance.updateMarker(marker)
        } else {
            mapProviderInstance.addMarker(marker)
        }
    }
    
    /// Remove a marker from the map
    public func removeMarker(withId id: String) {
        markersById.removeValue(forKey: id)
        mapProviderInstance.removeMarker(withId: id)
    }
    
    /// Remove all markers from the map
    public func clearAllMarkers() {
        markersById.removeAll()
        mapProviderInstance.clearAllMarkers()
    }
    
    /// Add a polyline to the map
    @discardableResult
    public func addPolyline(_ polyline: UniversalMapPolyline, animated: Bool = false) -> String {
        polylinesById[polyline.id] = polyline
        mapProviderInstance.addPolyline(polyline, animated: animated)
        return polyline.id
    }
    
    /// Remove a polyline from the map
    public func removePolyline(withId id: String) {
        polylinesById.removeValue(forKey: id)
        mapProviderInstance.removePolyline(withId: id)
    }
    
    /// Update an existing polyline with a new polyline object
    public func updatePolyline(_ polyline: UniversalMapPolyline, animated: Bool = false) {
        if polylinesById[polyline.id] != nil {
            polylinesById[polyline.id] = polyline
            mapProviderInstance.updatePolyline(polyline, animated: animated)
        } else {
            addPolyline(polyline, animated: animated)
        }
    }
    
    /// Update an existing polyline's coordinates by its ID
    /// - Parameters:
    ///   - id: The ID of the polyline to update
    ///   - coordinates: The new list of coordinates
    public func updatePolyline(id: String, coordinates: [CLLocationCoordinate2D], animated: Bool = false) {
        guard var polyline = polylinesById[id] else { return }
        polyline.coordinates = coordinates
        polylinesById[id] = polyline
        mapProviderInstance.updatePolyline(id: id, coordinates: coordinates, animated: animated)
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
    
    /// Get the current map view as a SwiftUI view.
    public func makeMapView() -> AnyView {
        return mapProviderInstance.makeMapView()
    }

    /// Get the current map as a native UIKit view controller (UIKit integration).
    @MainActor
    public func makeMapViewController() -> UIViewController {
        return mapProviderInstance.makeMapViewController()
    }
    
    public func setInteractionDelegate(_ delegate: any UniversalMapViewModelDelegate) {
        self.delegate = delegate
    }
    
    @MainActor
    public func focusToCurrentLocation(animated: Bool = true) {
        guard let location = self.mapProviderInstance.currentLocation else {
            Logging.l(tag: "UniversalMapViewModel", "Unable to get current location")
            return
        }
        
        self.mapProviderInstance.focusMap(
            on: location.coordinate,
            zoom: defaultZoomLevel,
            animated: animated
        )
    }
    
    public func set(hasAddressPicker: Bool) {
        uiState.hasAddressPicker = hasAddressPicker
    }
    
    public func set(hasAddressView: Bool) {
        uiState.hasAddressView = hasAddressView
    }
    
    @MainActor
    public func set(addressViewInfo: AddressInfo?) {
        uiState.addressInfo = addressViewInfo
    }
    
    @MainActor
    public func set(polylines: [UniversalMapPolyline], animated: Bool = false) {
        polylines.forEach { line in
            self.addPolyline(line, animated: animated)
        }
    }
    
    @MainActor
    public func setOrUpdate(polylines: [UniversalMapPolyline], animated: Bool = false) {
        let newIds = Set(polylines.map { $0.id })
        
        // Identify IDs to remove (present in current but not in new)
        let idsToRemove = polylinesById.keys.filter { !newIds.contains($0) }
        
        idsToRemove.forEach { removePolyline(withId: $0) }
        
        // Add or update
        polylines.forEach { polyline in
            if polylinesById[polyline.id] != nil {
                updatePolyline(polyline, animated: animated)
            } else {
                addPolyline(polyline, animated: animated)
            }
        }
    }
    
    @MainActor
    public func set(userLocationIcon: UIImage?, scale: CGFloat = 1.0) {
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
    
    // MARK: - Private Methods
    
    /// Update the map provider with all current configuration
    private func updateMapProviderConfiguration() {
        // Apply the current configuration
        if let camera = camera {
            mapProviderInstance.updateCamera(to: camera)
        }
        
        mapProviderInstance.showUserLocation(uiState.showUserLocation)
        _ = applyUserTrackingMode(
            uiState.userTrackingMode,
            reason: .programmatic,
            notifyDelegate: false
        )
        mapProviderInstance.setEdgeInsets(uiState.edgeInsets)
        if let tintColor {
            mapProviderInstance.setTintColor(tintColor)
        }
        
        // Re-add all markers
        for marker in markersById.values {
            mapProviderInstance.addMarker(marker)
        }
        
        // Re-add all polylines
        for polyline in polylines {
            mapProviderInstance.addPolyline(polyline, animated: false)
        }
    }

    @discardableResult
    private func applyUserTrackingMode(
        _ mode: UserLocationtrackingMode,
        reason: UserTrackingModeChangeReason,
        notifyDelegate: Bool = true
    ) -> Bool {
        let previousMode = uiState.userTrackingMode
        uiState.userTrackingMode = mode

        // Entering a tracking mode: snap to the user first so tracking starts centered on them.
        // The recenter is intentionally non-animated — tracking is enabled immediately below, and
        // an animated focus would be interrupted mid-flight by the first follow update, leaving the
        // user off-center.
        if mode != .none {
            focusToCurrentLocation(animated: false)
        }

        // MapPack owns user tracking behavior so Google and MapLibre behave the same.
        mapProviderInstance.setUserTrackingMode(mode: .none)
        locationTrackingManager.setTrackingLocationUpdatesEnabled(mode != .none)

        if mode == .course {
            if !deviceHeadingProvider.isUpdatingHeading {
                deviceHeadingProvider.startUpdatingHeading()
            }
        } else {
            deviceHeadingProvider.stopUpdatingHeading()
        }

        if mode == .none {
            latestDeviceHeading = nil
        }

        if notifyDelegate, previousMode != mode {
            delegate?.mapDidChangeUserTrackingMode(
                map: mapProviderInstance,
                mode: mode,
                reason: reason
            )
        }

        return true
    }

    private func observeLocationUpdates() {
        locationTrackingManager.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                Task { @MainActor in
                    self?.handleTrackedLocationUpdate(location)
                }
            }
            .store(in: &cancellables)
    }

    private func handleTrackedLocationUpdate(_ location: CLLocation) {
        switch uiState.userTrackingMode {
        case .none:
            return
        case .heading:
            followCurrentLocation(location)
        case .course:
            if let direction = courseTrackingDirection(for: location) {
                setDirection(direction, animated: true)
            }
            followCurrentLocation(location)
        }
    }

    private func followCurrentLocation(_ location: CLLocation) {
        let activeCamera = getCamera(animate: true) ?? camera
        let followCamera = UniversalMapCamera(
            center: location.coordinate,
            zoom: activeCamera?.zoom ?? defaultZoomLevel,
            bearing: activeCamera?.bearing ?? camera?.bearing ?? 0,
            pitch: activeCamera?.pitch ?? camera?.pitch ?? 0,
            animate: true,
            animationDuration: activeCamera?.animationDuration
        )
        updateCamera(to: followCamera)
    }

    private func courseTrackingDirection(for location: CLLocation) -> CLLocationDirection? {
        if location.course >= 0 {
            return location.course
        }

        return latestDeviceHeading?.degrees ?? deviceHeadingProvider.currentHeading?.degrees
    }

    func cancelUserTrackingForInteraction() {
        guard uiState.userTrackingMode != .none else { return }
        _ = applyUserTrackingMode(.none, reason: .userInteraction)
    }
}
