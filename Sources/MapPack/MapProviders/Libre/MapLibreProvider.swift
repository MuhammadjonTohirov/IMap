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

/// Implementation of the map provider protocol for MapLibre
public class MapLibreProvider: NSObject, MapProviderProtocol {
    var viewModel = MapLibreWrapperModel()
    private var mapStyle: UniversalMapStyle = .light
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
    
    private var polylines: [String: UniversalMapPolyline] = [:]
    
    required public override init() {
        super.init()
    }
    
    public func updateCamera(to camera: UniversalMapCamera) {
        self.mapCamera = camera.toMLNCamera()
    }
    
    public func setEdgeInsets(_ insets: UniversalMapEdgeInsets) {
        self.mapInsets = insets.toMapLibreEdgeInsets()
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
            coordinates: polyline.coordinates,
            title: polyline.title,
            color: polyline.color,
            width: polyline.width
        )
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
    
    public func setMapStyle(_ style: UniversalMapStyle) {
        self.mapStyle = style
        self.viewModel.mapView?.styleURL = URL(string: style.mapLibreStyleURL)
    }
    
    public func showUserLocation(_ show: Bool) {
        self.showsUserLocation = show
        self.viewModel.mapView?.showsUserLocation = show
    }
    
    public func setUserTrackingMode(_ tracking: Bool) {
        self.userTrackingMode = tracking ? .followWithHeading : nil
        self.viewModel.mapView?.userTrackingMode = tracking ? .followWithHeading : .none
    }
    
    public func setInteractionDelegate(_ delegate: MapInteractionDelegate?) {
        Logging.l("Set interaction delegate to \(String(describing: delegate))")
        self.viewModel.set(mapDelegate: delegate)
    }
    
    public func focusMap(on coordinate: CLLocationCoordinate2D, zoom: Double?, animated: Bool) {
        viewModel.centerMap(on: coordinate, zoom: zoom, animated: animated)
    }
    
    public func focusOnPolyline(id: String, padding: UIEdgeInsets, animated: Bool) {
        viewModel.focusOnPolyline(id: id)
    }
    
    public func focusOn(coordinates: [CLLocationCoordinate2D], edges: UIEdgeInsets, animated: Bool) {
        viewModel.focusOn(coordinates: coordinates, edges: edges, animated: animated)
    }

    public func setInput(input: any UniversalMapInputProvider) {
        self.viewModel.set(inputProvider: input)
    }
    
    @MainActor
    public func set(disabled: Bool) {
        self.viewModel.mapView?.isScrollEnabled = !disabled
    }
    
    public func makeMapView() -> AnyView {
        return AnyView(
            MLNMapViewWrapper(
                viewModel: viewModel,
                camera: mapCamera,
                styleUrl: mapStyle.mapLibreStyleURL,
                inset: mapInsets,
                trackingMode: userTrackingMode,
                showsUserLocation: showsUserLocation
            )
        )
    }
}
