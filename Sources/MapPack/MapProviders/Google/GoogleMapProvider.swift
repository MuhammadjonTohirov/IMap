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
    private var userLocationImage: UIImage?
    private var userLocationIconScale: CGFloat = 1.0
    private let userLocationMarkerId = "USER_LOCATION_MARKER"
    private var shouldShowUserLocation: Bool = false
    private var lastKnownLocation: CLLocation?
    private var accuracyCircle: GMSCircle?
    
    public var currentLocation: CLLocation? {
        lastKnownLocation ?? self.viewModel.mapView?.myLocation
    }
    
    public var markers: [String : any UniversalMapMarkerProtocol] {
        viewModel.allMarkers
    }
    
    required public override init() {
        super.init()
    }
    
    public func setUserLocationIcon(_ image: UIImage, scale: CGFloat) {
        self.userLocationImage = image
        self.userLocationIconScale = scale
        self.showUserLocation(self.shouldShowUserLocation)
    }
    
    public func updateUserLocation(_ location: CLLocation) {
        self.lastKnownLocation = location
        
        guard let icon = userLocationImage, shouldShowUserLocation else { 
            accuracyCircle?.map = nil
            return 
        }
        
        // Update Marker
        if viewModel.markers[userLocationMarkerId] == nil {
             let imageView = UIImageView(image: icon)
             imageView.contentMode = .scaleAspectFit
             imageView.frame = CGRect(x: 0, y: 0, width: icon.size.width * userLocationIconScale, height: icon.size.height * userLocationIconScale)
             
             let m = UniversalMarker(id: userLocationMarkerId, coordinate: location.coordinate, view: imageView)
             m.groundAnchor = CGPoint(x: 0.5, y: 0.5)
             m.zIndex = 1000 // High zIndex
             viewModel.addMarker(id: userLocationMarkerId, marker: m)
        } else {
             // Update position
             let m = viewModel.allMarkers[userLocationMarkerId]
             m?.set(coordinate: location.coordinate)
             if let m = m {
                 viewModel.updateMarker(m)
             }
        }
        
        // Update Accuracy Circle
        if accuracyCircle == nil {
            accuracyCircle = GMSCircle()
            accuracyCircle?.fillColor = UIColor.systemBlue.withAlphaComponent(0.2)
            accuracyCircle?.strokeColor = UIColor.systemBlue.withAlphaComponent(0.6)
            accuracyCircle?.strokeWidth = 1
            accuracyCircle?.zIndex = 999 // Just below the marker
        }
        
        accuracyCircle?.position = location.coordinate
        accuracyCircle?.radius = location.horizontalAccuracy
        accuracyCircle?.map = viewModel.mapView
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
        self.shouldShowUserLocation = show
        
        if let _ = userLocationImage {
            // Custom marker mode
            viewModel.mapView?.isMyLocationEnabled = false
            if show {
                 // Trigger an update if we have a location
                 if let loc = currentLocation {
                     updateUserLocation(loc)
                 }
            } else {
                 viewModel.removeMarker(id: userLocationMarkerId)
                 accuracyCircle?.map = nil
            }
        } else {
            viewModel.mapView?.isMyLocationEnabled = show
            if !show {
                viewModel.removeMarker(id: userLocationMarkerId)
                accuracyCircle?.map = nil
            }
        }
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
