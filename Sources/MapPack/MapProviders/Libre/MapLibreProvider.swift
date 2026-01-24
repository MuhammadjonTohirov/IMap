//
//  LibreMapProvider.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

// UniversalMap/Providers/MapLibre/MapLibreProvider.swift
import Foundation
import SwiftUI
import MapLibre
import CoreLocation

public struct MapLibreLightStyle: UniversalMapStyleProtocol {
    public var source: String {
        "https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json"
    }
    
    public init() {
        
    }
}

/// Implementation of the map provider protocol for MapLibre
public class MapLibreProvider: NSObject, @preconcurrency MapProviderProtocol {
    public private(set) var viewModel = MapLibreWrapperModel()
    private var mapCamera: MapCamera?
    private var mapInsets: MapEdgeInsets?
    private var showsUserLocation: Bool = true
    private var userTrackingMode: MLNUserTrackingMode?
    
    public var currentLocation: CLLocation? {
        self.viewModel.mapView?.userLocation?.location
    }
    
    public var markers: [String: any UniversalMapMarkerProtocol] {
        viewModel.markers
    }
    
    public var polylines: [String: UniversalMapPolyline] = [:]
    
    required public override init() {
        super.init()
    }
    
    @MainActor
    public func updateCamera(to camera: UniversalMapCamera) {
        guard let mapView = viewModel.mapView else { return }
        
        // Use the actual map view width in points; fall back to screen width if needed
        let widthPoints = mapView.bounds.width > 0 ? mapView.bounds.width : UIScreen.main.bounds.width
        
        let acrossDistance = viewModel.metersAcrossAtZoomLevel(
            camera.zoom,
            latitude: camera.center.latitude,
            screenWidthPoints: widthPoints
        )
        
        let targetCamera = MLNMapCamera(
            lookingAtCenter: camera.center,
            acrossDistance: acrossDistance,
            pitch: camera.pitch,
            heading: camera.bearing
        )
        
        if camera.animate {
            mapView.setCamera(
                targetCamera,
                withDuration: 1, // Smooth animation duration
                animationTimingFunction: CAMediaTimingFunction(name: .linear)
            ) {
                Logging.l(tag: "MapLibre", "Camera animation completed")
            }
        } else {
            mapView.camera = targetCamera
        }
    }
    
    @MainActor
    public func set(preferredRefreshRate: MapRefreshRate) {
        self.viewModel.set(preferredRefreshRate: preferredRefreshRate)
    }
    
    public func setUserLocationIcon(_ image: UIImage, scale: CGFloat) {
        viewModel.userLocationImage = image
        viewModel.userLocationIconScale = scale
        // Trigger a refresh if needed, but typically MapLibre asks for view when location updates or map moves.
        // We might need to force a refresh of user location annotation.
        if let userLocation = viewModel.mapView?.userLocation {
            viewModel.mapView?.removeAnnotation(userLocation)
            // showsUserLocation toggle might force re-add
            if showsUserLocation {
                viewModel.mapView?.showsUserLocation = false
                viewModel.mapView?.showsUserLocation = true
            }
        }
    }
    
    public func setEdgeInsets(_ insets: UniversalMapEdgeInsets) {
        self.mapInsets = insets.toMapLibreEdgeInsets()
        if insets.animated {
            viewModel.mapView?.setContentInset(insets.insets, animated: insets.animated, completionHandler: insets.onEnd)
        } else  {
            viewModel.mapView?.contentInset = insets.insets
            insets.onEnd?()
        }
    }
    
    public func addMarker(_ marker: any UniversalMapMarkerProtocol) {
        viewModel.addMarker(marker)
    }
    
    public func marker(byId id: String) -> (any UniversalMapMarkerProtocol)? {
        self.markers[id]
    }
    
    public func updateMarker(_ marker: any UniversalMapMarkerProtocol) {
        viewModel.updateMarker(marker)
    }
    
    public func removeMarker(withId id: String) {
        if markers[id] != nil {
            viewModel.removeMarker(withId: id)
        }
    }
    
    public func clearAllMarkers() {
        viewModel.clearAllMarkers()
    }
    
    public func addPolyline(_ polyline: UniversalMapPolyline) {
        polylines[polyline.id] = polyline

        viewModel.addPolyline(
            id: polyline.id,
            coordinates: polyline.coordinates,
            title: polyline.title,
            color: polyline.color,
            width: polyline.width
        )
    }
    
    public func updatePolyline(_ polyline: UniversalMapPolyline) {
        polylines[polyline.id] = polyline
        // Update coordinates
        viewModel.updatePolyline(id: polyline.id, coordinates: polyline.coordinates)
        // Update style
        viewModel.updatePolyline(id: polyline.id, color: polyline.color, width: polyline.width)
    }
    
    public func updatePolyline(id: String, coordinates: [CLLocationCoordinate2D]) {
        if var p = polylines[id] {
            p.coordinates = coordinates
            polylines[id] = p
        }
        viewModel.updatePolyline(id: id, coordinates: coordinates)
    }
    
    public func removePolyline(withId id: String) {
        if polylines[id] != nil {
            // Find the MapLibre polyline with matching ID
            if let index = viewModel.savedPolylines.firstIndex(where: { $0.id == id }) {
                // Remove it
                viewModel.savedPolylines.remove(at: index)
                polylines.removeValue(forKey: id)
            }
        }
    }
    
    public func clearAllPolylines() {
        viewModel.clearAllPolylines()
        polylines.removeAll()
    }
    
    @MainActor
    public func setMapStyle(_ style: (any UniversalMapStyleProtocol)?, scheme: ColorScheme) {
        if var config = viewModel.config {
            switch scheme {
            case .dark:
                config.darkStyle = style?.source ?? config.darkStyle
            default:
                config.lightStyle = style?.source ?? config.lightStyle
            }

            self.viewModel.set(config: config)

            self.viewModel.resetStyleFallbackState()
            self.viewModel.mapView?.styleURL = URL(string: (scheme == .dark) ? config.darkStyle : config.lightStyle)
        }
    }
    
    public func showUserLocation(_ show: Bool) {
        self.showsUserLocation = show
        self.viewModel.mapView?.showsUserLocation = show
    }
    
    public func showBuildings(_ show: Bool) {
        self.viewModel.toggleBuildings(visible: show)
    }
     
    public func setMaxMinZoomLevels(min: Double = 4, max: Double = 18) {
        self.viewModel.mapView?.minimumZoomLevel = min
        self.viewModel.mapView?.maximumZoomLevel = max
    }
    
    public func setUserTrackingMode(_ tracking: Bool) {
        self.userTrackingMode = tracking ? .followWithHeading : nil
        self.viewModel.mapView?.userTrackingMode = tracking ? .followWithHeading : .none
    }
    
    public func showUserLocationAccuracy(_ show: Bool) {
        if let mapView = viewModel.mapView,
           let userLocationAnnotation = mapView.userLocation,
           let view = mapView.view(for: userLocationAnnotation) as? UniversalUserLocationAnnotationView {
            view.setCircleHidden(!show)
            // Trigger layout update
            if show {
                view.updateZoom(mapView.zoomLevel)
            }
        }
    }
    
    public func setInteractionDelegate(_ delegate: MapInteractionDelegate?) {
        Logging.l("Set interaction delegate to \(String(describing: delegate))")
        self.viewModel.set(mapDelegate: delegate)
    }
    
    public func focusMap(on coordinate: CLLocationCoordinate2D, zoom: Double?, animated: Bool) {
        viewModel.centerMap(on: coordinate, zoom: zoom, animated: animated)
    }
    
    public func focusOnPolyline(id: String, padding: UIEdgeInsets, animated: Bool) {
        viewModel.focusOnPolyline(id: id, padding: padding, animated: animated)
    }
    
    public func focusOnPolyline(id: String, animated: Bool) {
        viewModel.focusOnPolyline(id: id, animated: animated)
    }
    
    public func focusOn(coordinates: [CLLocationCoordinate2D], edges: UIEdgeInsets, animated: Bool) {
        viewModel.focusOn(coordinates: coordinates, edges: edges, animated: animated)
    }

    @MainActor
    public func setConfig(_ input: any UniversalMapConfigProtocol) {
        self.viewModel.set(config: input)
    }
    
    @MainActor
    public func set(disabled: Bool) {
        self.viewModel.mapView?.isScrollEnabled = !disabled
    }
    
    @MainActor
    public func zoomOut(minLevel: Float = 10, shift: Double = 0.5) {
        self.viewModel.zoomOut(minLevel: minLevel, shift: shift)
    }
    
    public func updateUserLocation(_ location: CLLocation) {
        viewModel.updateUserLocation(location)
    }
    
    public func makeMapView() -> AnyView {
        
        return AnyView(
            MapLibreMapView(
                viewModel: self.viewModel,
                delegate: viewModel,
                camera: mapCamera,
                styleUrl: viewModel.config?.lightStyle,
                inset: mapInsets,
                trackingMode: userTrackingMode,
                showsUserLocation: showsUserLocation
            )
        )
    }
}

