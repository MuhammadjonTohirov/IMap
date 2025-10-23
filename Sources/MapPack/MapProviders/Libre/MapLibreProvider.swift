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

public struct MapLibreConfig {
    public static var shared: MapLibreConfig = .init()
    
    public var darkStyleUrl: URL?
    public var liteStyleUrl: URL?
    
    public init(
        darkStyleUrl: URL? = .init(string: "https://pnorman.github.io/tilekiln-shortbread-demo/colorful.json"),
        liteStyleUrl: URL? = .init(string: "https://pnorman.github.io/tilekiln-shortbread-demo/colorful.json")
    ) {
        self.darkStyleUrl = darkStyleUrl
        self.liteStyleUrl = liteStyleUrl
    }
}

/// Implementation of the map provider protocol for MapLibre
public class MapLibreProvider: NSObject, MapProviderProtocol {
    public private(set) var viewModel = MapLibreWrapperModel()
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
    
    public var polylines: [String: UniversalMapPolyline] = [:]
    
    required public override init() {
        super.init()
    }
    
    public func updateCamera(to camera: UniversalMapCamera) {
        guard let mapView = viewModel.mapView else { return }
        
        let acrossDistance = viewModel.metersAcrossAtZoomLevel(
            camera.zoom,
            latitude: camera.center.latitude,
            screenWidthPoints: UIApplication.shared.screenFrame.width
        )
        
        let targetCamera = MLNMapCamera(lookingAtCenter: camera.center, acrossDistance: acrossDistance, pitch: camera.pitch, heading: camera.bearing)
        
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
    
    public func showBuildings(_ show: Bool) {
        // map libre does not provide runtime buildings visability
        debugPrint("map libre does not provide runtime buildings visability")
    }
     
    public func setMaxMinZoomLevels(min: Double = 4, max: Double = 18) {
        self.viewModel.mapView?.minimumZoomLevel = min
        self.viewModel.mapView?.maximumZoomLevel = max
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
    
    @MainActor
    public func zoomOut(minLevel: Float = 10, shift: Double = 0.5) {
        self.viewModel.zoomOut(minLevel: minLevel, shift: shift)
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
