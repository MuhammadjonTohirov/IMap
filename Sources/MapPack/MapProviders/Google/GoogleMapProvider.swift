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
    private var mapOptions = GMSMapViewOptions()

    required public override init() {
        super.init()
    }
    
    public func updateCamera(to camera: UniversalMapCamera) {
        viewModel.mapView?.camera = .camera(withTarget: camera.center, zoom: 14)
    }
    
    public func setEdgeInsets(_ insets: UniversalMapEdgeInsets) {
        viewModel.mapView?.padding = insets.insets
    }
    
    public func addMarker(_ marker: UniversalMapMarker) {
        let marker = marker.toGMSMarker()

        assert(marker.accessibilityLabel != nil)

        viewModel.addMarker(id: marker.accessibilityLabel ?? "", marker: marker)
    }
    
    public func removeMarker(withId id: String) {
        viewModel.removeMarker(id: id)
    }
    
    public func clearAllMarkers() {
        viewModel.removeAllMarkers()
    }
    
    public func addPolyline(_ polyline: UniversalMapPolyline) {
        self.viewModel.addPolyline(id: polyline.id, polyline: polyline.gmsPolyline())
    }
    
    public func removePolyline(withId id: String) {
        self.viewModel.removePolyline(id: id)
    }
    
    public func clearAllPolylines() {
        self.viewModel.removeAllPolylines()
    }
    
    public func setMapStyle(_ style: UniversalMapStyle) {
        self.viewModel.mapView?.mapStyle = try? .init(jsonString: style.googleMapStyle)
    }
    
    public func showUserLocation(_ show: Bool) {
        viewModel.mapView?.isMyLocationEnabled = show
    }
    
    public func setUserTrackingMode(_ tracking: Bool) {
        // TODO: needs to implement if possible
    }
    
    public func setInteractionDelegate(_ delegate: MapInteractionDelegate?) {
        self.viewModel.set(mapDelegate: delegate)
    }
    
    public func focusMap(on coordinate: CLLocationCoordinate2D, zoom: Double?) {
        viewModel.focusTo(coordinate: coordinate, zoom: Float(zoom ?? 0))
    }
    
    /// `animate` will be ignored
    public func focusOnPolyline(id: String, padding: UIEdgeInsets, animated: Bool) {
        viewModel.focusTo(polyline: id, edges: padding)
    }
    
    @MainActor
    public func setInput(input: any UniversalMapInputProvider) {
        self.viewModel.set(inputProvider: input)
    }
    
    public func makeMapView() -> AnyView {
        return AnyView(
            GoogleMapView(
                viewModel: viewModel,
                options: mapOptions
            )
        )
    }
}
