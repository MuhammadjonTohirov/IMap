//
//  GoogleMapProvider.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

// UniversalMap/Providers/GoogleMaps/GoogleMapsProvider.swift
import Foundation
import SwiftUI
import GoogleMaps

/// Implementation of the map provider protocol for Google Maps
public class GoogleMapsProvider: NSObject, @preconcurrency MapProviderProtocol {
    private var viewModel: GoogleMapsViewWrapperModel = .init()
    
    public private(set) var polylines: [String : UniversalMapPolyline] = [:]
    
    private var mapOptions = GMSMapViewOptions()
    
    public var currentLocation: CLLocation? {
        self.viewModel.mapView?.myLocation
    }
    
    public var markers: [String : any UniversalMapMarkerProtocol] {
        viewModel.markers
    }
    
    required public override init() {
        super.init()
    }
    
    public func updateCamera(to camera: UniversalMapCamera) {
        if camera.animate {
            viewModel.mapView?.animate(to: .camera(withTarget: camera.center, zoom: Float(camera.zoom)))
        } else {
            viewModel.mapView?.camera = .camera(withTarget: camera.center, zoom: Float(camera.zoom))
        }
    }
    
    public func setEdgeInsets(_ insets: UniversalMapEdgeInsets) {
        viewModel.mapView?.padding.top = insets.insets.top
        viewModel.mapView?.padding.left = insets.insets.left
        viewModel.mapView?.padding.right = insets.insets.right
        viewModel.mapView?.padding.bottom = insets.insets.bottom
    }
    
    @MainActor
    public func set(preferredRefreshRate: MapRefreshRate) {
        self.viewModel.set(preferredRefreshRate: preferredRefreshRate)
    }
    
    public func addMarker(_ marker: any UniversalMapMarkerProtocol) {
        guard let marker = marker as? UniversalMarker else {
            return
        }

        assert(marker.accessibilityLabel != nil)

        viewModel.addMarker(id: marker.accessibilityLabel ?? "", marker: marker)
    }
    
    public func marker(byId id: String) -> (any UniversalMapMarkerProtocol)? {
        markers[id]
    }
    
    public func removeMarker(withId id: String) {
        viewModel.removeMarker(id: id)
    }
    
    public func updateMarker(_ marker: any UniversalMapMarkerProtocol) {
        let mrk = self.viewModel.markers[marker.id]
        
        mrk?.set(coordinate: marker.coordinate)
        mrk?.set(heading: marker.rotation)
    }
    
    public func clearAllMarkers() {
        viewModel.removeAllMarkers()
    }
    
    public func addPolyline(_ polyline: UniversalMapPolyline) {
        self.polylines[polyline.id] = polyline
        self.viewModel.addPolyline(id: polyline.id, polyline: polyline.gmsPolyline())
    }
    
    public func removePolyline(withId id: String) {
        self.viewModel.removePolyline(id: id)
        self.polylines.removeValue(forKey: id)
    }
    
    public func clearAllPolylines() {
        self.viewModel.removeAllPolylines()
        self.polylines.removeAll()
    }
    
    @MainActor
    public func setMapStyle(_ style: (any UniversalMapStyleProtocol)?, scheme: ColorScheme) {
        if var config = self.viewModel.config { // this scope will help to replace existing map style with new one based on scheme
            switch scheme {
            case .light:
                config.lightStyle = style?.source ?? config.lightStyle
            default:
                config.darkStyle = style?.source ?? config.darkStyle
            }

            self.viewModel.mapView?.mapStyle = try? .init(jsonString: scheme == .dark ? config.darkStyle : config.lightStyle)

            self.viewModel.set(config: config)
        }
    }
    
    public func showUserLocation(_ show: Bool) {
        viewModel.mapView?.isMyLocationEnabled = show
    }
    
    public func showBuildings(_ show: Bool) {
        viewModel.mapView?.isBuildingsEnabled = show
    }
    
    public func setMaxMinZoomLevels(min: Double, max: Double) {
        viewModel.mapView?.setMinZoom(Float(min), maxZoom: Float(max))
    }
    
    public func setUserTrackingMode(_ tracking: Bool) {
        // TODO: needs to implement if possible
    }
    
    public func setInteractionDelegate(_ delegate: MapInteractionDelegate?) {
        self.viewModel.set(mapDelegate: delegate)
    }
    
    public func focusMap(on coordinate: CLLocationCoordinate2D, zoom: Double?, animated: Bool) {
        viewModel.focusTo(coordinate: coordinate, zoom: Float(zoom ?? 0), animate: animated)
    }
    
    public func focusOn(coordinates: [CLLocationCoordinate2D], edges: UIEdgeInsets, animated: Bool) {
        focusOn(coordinates: coordinates, padding: edges.top, animated: animated)
    }
    
    public func focusOn(coordinates: [CLLocationCoordinate2D], padding: CGFloat, animated: Bool) {
        viewModel.focusTo(coordinates: coordinates, padding: padding, animated: animated)
    }
    
    /// `animate` will be ignored
    public func focusOnPolyline(id: String, padding: UIEdgeInsets, animated: Bool) {
        viewModel.focusTo(polyline: id, edges: padding, animate: animated)
    }
    
    public func focusOnPolyline(id: String, animated: Bool) {
        viewModel.focusTo(polyline: id, edges: .zero, animate: animated)
    }
    
    @MainActor
    public func setConfig(_ config: any UniversalMapConfigProtocol) {
        self.viewModel.set(config: config)
    }
    
    @MainActor
    public func set(disabled: Bool) {
        self.viewModel.mapView?.isUserInteractionEnabled = !disabled
    }
    
    public func makeMapView() -> AnyView {
        return AnyView(
            GoogleMapView(
                viewModel: viewModel,
                options: mapOptions
            )
        )
    }
    
    @MainActor
    public func zoomOut(minLevel: Float = 10, shift: Double = 0.5) {
        self.viewModel.zoomOut(minLevel: minLevel, shift: shift)
    }
}
