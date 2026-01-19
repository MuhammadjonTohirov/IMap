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
import CoreLocation

class UserLocationMarkerView: UIView {
    private let iconView: UIImageView
    private let circleView: UIView
    private var iconSize: CGSize
    
    // State
    private var lastAccuracy: CLLocationAccuracy = 0
    private var lastLatitude: CLLocationDegrees = 0
    private var isCircleHidden: Bool = false
    
    init(icon: UIImage, scale: CGFloat) {
        self.iconSize = CGSize(width: icon.size.width * scale, height: icon.size.height * scale)
        self.iconView = UIImageView(image: icon)
        self.circleView = UIView()
        super.init(frame: .init(origin: .zero, size: iconSize))
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Circle setup
        circleView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        circleView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.6).cgColor
        circleView.layer.borderWidth = 1
        circleView.isUserInteractionEnabled = false
        addSubview(circleView)
        
        // Icon setup
        iconView.contentMode = .scaleAspectFit
        iconView.frame = CGRect(origin: .zero, size: iconSize)
        addSubview(iconView)
        
        // Center icon initially
        iconView.center = center
    }
    
    func setCircleHidden(_ hidden: Bool) {
        self.isCircleHidden = hidden
        self.circleView.isHidden = hidden
    }
    
    func update(accuracy: CLLocationAccuracy, zoom: Float, latitude: CLLocationDegrees) {
        self.lastAccuracy = accuracy
        self.lastLatitude = latitude
        updateLayout(zoom: zoom)
    }
    
    func updateZoom(_ zoom: Float) {
        updateLayout(zoom: zoom)
    }
    
    private func updateLayout(zoom: Float) {
        if isCircleHidden { return }
        
        // Calculate radius in points
        let metersPerPoint = 156543.03392 * cos(lastLatitude * .pi / 180) / pow(2, Double(zoom))
        let radiusPoints = CGFloat(lastAccuracy / metersPerPoint)
        
        // Diameter
        let diameter = radiusPoints * 2
        
        // Ensure container is large enough
        let maxSize = max(diameter, max(iconSize.width, iconSize.height))
        let newFrame = CGRect(x: 0, y: 0, width: maxSize, height: maxSize)
        
        // Only update if frame changed significantly
        if abs(newFrame.width - self.frame.width) > 0.5 {
            self.frame = newFrame
            self.iconView.center = CGPoint(x: maxSize / 2, y: maxSize / 2)
        }
        
        // Update circle
        let circleFrame = CGRect(x: (maxSize - diameter) / 2, y: (maxSize - diameter) / 2, width: diameter, height: diameter)
        
        if circleView.frame != circleFrame {
             circleView.frame = circleFrame
             circleView.layer.cornerRadius = diameter / 2
        }
    }
}

/// Implementation of the map provider protocol for Google Maps
public class GoogleMapsProvider: NSObject, @preconcurrency MapProviderProtocol, CLLocationManagerDelegate {
    private var viewModel: GoogleMapsViewWrapperModel = .init()
    
    public private(set) var polylines: [String : UniversalMapPolyline] = [:]
    
    private var mapOptions = GMSMapViewOptions()
    private var userLocationImage: UIImage?
    private var userLocationIconScale: CGFloat = 1.0
    private let userLocationMarkerId = "USER_LOCATION_MARKER"
    private var shouldShowUserLocation: Bool = false
    private var lastKnownLocation: CLLocation?
    
    private let locationManager = CLLocationManager()
    
    public var currentLocation: CLLocation? {
        lastKnownLocation ?? self.viewModel.mapView?.myLocation
    }
    
    public var markers: [String : any UniversalMapMarkerProtocol] {
        viewModel.allMarkers
    }
    
    required public override init() {
        super.init()
        locationManager.delegate = self
    }
    
    public func showUserLocationAccuracy(_ show: Bool) {
        if let userMarker = viewModel.markers[userLocationMarkerId],
           let view = userMarker.iconView as? UserLocationMarkerView {
            view.setCircleHidden(!show)
            // Trigger layout update if showing
            if show, let zoom = viewModel.mapView?.camera.zoom {
                view.updateZoom(zoom)
            }
        }
    }
    
    public func setUserLocationIcon(_ image: UIImage, scale: CGFloat) {
        self.userLocationImage = image
        self.userLocationIconScale = scale
        self.showUserLocation(self.shouldShowUserLocation)
    }
    
    public func updateUserLocation(_ location: CLLocation) {
        self.lastKnownLocation = location
        
        guard let icon = userLocationImage, shouldShowUserLocation else { 
            return 
        }
        
        // Update Marker
        if viewModel.markers[userLocationMarkerId] == nil {
             // We will implement the custom view logic in the ViewModel or here
             // For now, let's just pass the icon and accuracy to the view model helper
             // But first, we need to update the ViewModel to handle this "Circle View" logic.
             // I'll keep the basic marker creation here for a moment, but it will change.
             
             let container = UserLocationMarkerView(icon: icon, scale: userLocationIconScale)
             
             let m = UniversalMarker(id: userLocationMarkerId, coordinate: location.coordinate, view: container)
             m.groundAnchor = CGPoint(x: 0.5, y: 0.5)
             m.zIndex = 1000 // High zIndex
             m.tracksViewChanges = true // Essential for animation
             viewModel.addMarker(id: userLocationMarkerId, marker: m)
             
             // Initial update
             container.update(accuracy: location.horizontalAccuracy, zoom: viewModel.mapView?.camera.zoom ?? 15, latitude: location.coordinate.latitude)
        } else {
             // Update position
             let m = viewModel.allMarkers[userLocationMarkerId]
             m?.set(coordinate: location.coordinate)
             
             if let container = m?.iconView as? UserLocationMarkerView {
                 container.update(accuracy: location.horizontalAccuracy, zoom: viewModel.mapView?.camera.zoom ?? 15, latitude: location.coordinate.latitude)
             }
             
             if let m = m {
                 viewModel.updateMarker(m)
             }
        }
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
                 locationManager.startUpdatingLocation()
                 // Trigger an update if we have a location
                 if let loc = currentLocation {
                     updateUserLocation(loc)
                 }
            } else {
                 locationManager.stopUpdatingLocation()
                 viewModel.removeMarker(id: userLocationMarkerId)
            }
        } else {
            locationManager.stopUpdatingLocation()
            viewModel.mapView?.isMyLocationEnabled = show
            if !show {
                viewModel.removeMarker(id: userLocationMarkerId)
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
    
    // MARK: - CLLocationManagerDelegate
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        updateUserLocation(location)
    }
}
