//
//  MapLibreWrapperModel.swift
//  LibreMap
//
//  Created by Muhammadjon Tohirov on 07/05/25.
//
// MapLibreWrapperModel.swift

import Foundation
import MapLibre
import SwiftUI
import Combine

public protocol LibreMapsKeyProvider: UniversalMapInputProvider, AnyObject {
    
}

open class MapLibreWrapperModel: NSObject, ObservableObject {
    // Map view reference
    public private(set) weak var mapView: MLNMapView?
    
    // Published properties
    @Published var isDrawingPolyline: Bool = false
    @Published var drawingCoordinates: [CLLocationCoordinate2D] = []
    @Published var savedPolylines: [MapPolyline] = []
    @Published var userLocation: CLLocation?
    @Published var mapCenter: CLLocationCoordinate2D?
    @Published var zoomLevel: Double = 15
    @Published var isMapLoaded: Bool = false
    // Map markers
    @Published var markers: [String: UniversalMarker] = [:]
        
    public private(set) weak var interactionDelegate: MapInteractionDelegate?

    // Temporary source and layer IDs
    let tempPolylineSourceID = "temp-polyline-source"
    let tempPolylineLayerID = "temp-polyline-layer"
    
    func set(inputProvider: any UniversalMapInputProvider) {
        guard let _ = inputProvider as? LibreMapsKeyProvider else { return }
        
    }
    
    func set(mapView: MLNMapView?) {
        self.mapView = mapView
    }
    
    // MARK: - Custom Methods
    
    func centerMap(on coordinate: CLLocationCoordinate2D, zoom: Double? = nil, animated: Bool = true) {
        guard let mapView = mapView else { return }
        let _zoom = (zoom ?? self.zoomLevel) / 1.036
        let acrossDistance = metersAcrossAtZoomLevel(
            _zoom,
            latitude: coordinate.latitude,
            screenWidthPoints: UIApplication.shared.screenFrame.width
        )
        
        let camera = MLNMapCamera(
            lookingAtCenter: coordinate,
            acrossDistance: acrossDistance,
            pitch: 0,
            heading: 0
        )

        mapView.setCamera(camera, animated: animated)
    }
    
    func flyTo(coordinate: CLLocationCoordinate2D, zoom: Double? = nil, animated: Bool = true) {
        guard let mapView = mapView else { return }
        let _zoom = (zoom ?? self.zoomLevel) / 1.036
        let acrossDistance = metersAcrossAtZoomLevel(
            _zoom,
            latitude: coordinate.latitude,
            screenWidthPoints: UIApplication.shared.screenFrame.width
        )
        let camera = MLNMapCamera(lookingAtCenter: coordinate,
                                 acrossDistance: acrossDistance,
                                 pitch: 0,
                                 heading: 0)
        
        if let zoom = zoom {
            mapView.zoomLevel = zoom
        }
        
        mapView.setCamera(camera, animated: animated)
    }
    
    func set(mapDelegate: MapInteractionDelegate?) {
        self.interactionDelegate = mapDelegate
    }
    
    func setupGestureLocker() {
        mapView?.gestureRecognizers?.forEach { gesture in
            if gesture is UIPinchGestureRecognizer || gesture is UIRotationGestureRecognizer {
                gesture.addTarget(self, action: #selector(lockPanDuringGesture(_:)))
            }
        }
    }
    
    @objc func lockPanDuringGesture(_ gesture: UIGestureRecognizer) {
        switch gesture.state {
        case .began:
            mapView?.isScrollEnabled = false
            mapView?.allowsScrolling = false
        case .ended, .cancelled, .failed:
            mapView?.isScrollEnabled = true
            mapView?.allowsScrolling = true
        default:
            break
        }
    }
    
    func zoomOut(minLevel: Float = 10, shift: Double = 0.5) {
        guard let mapView = self.mapView else { return }
        
        let currentZoom = mapView.zoomLevel
        let targetZoom = Double(minLevel)
        
        let newZoom = max(currentZoom - shift, targetZoom)
        
        // Animate to a zoomed-out level
        mapView.setCamera(
            mapView.camera,
            withDuration: 0.2,
            animationTimingFunction: CAMediaTimingFunction(name: .easeInEaseOut)
        )
        mapView.setZoomLevel(newZoom, animated: true)
    }
}

extension MapLibreWrapperModel {
    // MARK: - Marker Management
    
    func addMarker(_ marker: any UniversalMapMarkerProtocol) {
        guard let marker = marker as? UniversalMarker else { return }
        
        Logging.l("Add marker to map view by id: \(marker.id)")
        markers[marker.id] = marker
        addMarkerToMap(marker)
    }
    
    func removeMarker(withId id: String) {
        guard let mapView = mapView else { return }
        
        if let annotation = mapView.annotations?.first(where: { ($0 as? UniversalMarker)?.id == id }) {
            Logging.l("Remove marker from map view by id: \(id)")
            mapView.removeAnnotation(annotation)
        }
        
        markers.removeValue(forKey: id)
    }
    
    func clearAllMarkers() {
        guard let mapView = mapView else { return }

        mapView.annotations?.forEach { annotation in
            mapView.removeAnnotation(annotation)
        }
        
        markers.removeAll()
    }
    
    private func addMarkerToMap(_ marker: UniversalMarker) {
        guard let mapView = mapView else { return }
        mapView.addAnnotation(marker)
    }
    
    func focusOn(coordinates: [CLLocationCoordinate2D], edges: UIEdgeInsets, animated: Bool) {
        self.mapView?.setVisibleCoordinates(coordinates, count: UInt(coordinates.count), edgePadding: edges, animated: animated)
    }
}

extension MLNPointAnnotation {
    var identifier: String {
        "\(self.coordinate.latitude),\(self.coordinate.longitude)"
    }
}

extension MLNAnnotation {
    var identifier: String {
        "\(self.coordinate.latitude),\(self.coordinate.longitude)"
    }
}

extension MapLibreWrapperModel {
    func metersAcrossAtZoomLevel(_ zoomLevel: Double, latitude: CLLocationDegrees, screenWidthPoints: CGFloat, scale: CGFloat = UIScreen.main.scale) -> Double {
        let earthCircumference: Double = 40075016.686
        let tileSize: Double = 256.0
        let latitudeRadians = latitude * Double.pi / 180.0
        let mapPixelSize = tileSize * pow(2.0, zoomLevel)
        let metersPerPixel = (earthCircumference * cos(latitudeRadians)) / mapPixelSize
        let screenWidthPixels = Double(screenWidthPoints) * Double(scale)

        return metersPerPixel * screenWidthPixels
    }
}
