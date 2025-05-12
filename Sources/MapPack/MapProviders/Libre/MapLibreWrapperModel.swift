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
    weak var mapView: MLNMapView?
    
    // Published properties
    @Published var isDrawingPolyline: Bool = false
    @Published var drawingCoordinates: [CLLocationCoordinate2D] = []
    @Published var savedPolylines: [MapPolyline] = []
    @Published var userLocation: CLLocation?
    @Published var mapCenter: CLLocationCoordinate2D?
    @Published var zoomLevel: Double = 15
    @Published var isMapLoaded: Bool = false
    // Map markers
    @Published var markers: [MapMarker] = []

    public private(set) weak var interactionDelegate: MapInteractionDelegate?

    // Temporary source and layer IDs
    let tempPolylineSourceID = "temp-polyline-source"
    let tempPolylineLayerID = "temp-polyline-layer"
    
    func set(inputProvider: any UniversalMapInputProvider) {
        guard let _ = inputProvider as? LibreMapsKeyProvider else { return }
        
    }
    
    // MARK: - Custom Methods
    
    func centerMap(on coordinate: CLLocationCoordinate2D, zoom: Double? = nil, animated: Bool = true) {
        guard let mapView = mapView else { return }
        let acrossDistance = metersAcross(zoomLevel: zoom ?? 25, latitude: coordinate.latitude, screenWidthPoints: UIApplication.shared.screenFrame.width)
        let camera = MLNMapCamera(lookingAtCenter: coordinate,
                                 acrossDistance: acrossDistance,
                                 pitch: 0,
                                 heading: 0)

        mapView.setCamera(camera, animated: animated)
    }
    
    func flyTo(coordinate: CLLocationCoordinate2D, zoom: Double? = nil) {
        guard let mapView = mapView else { return }
        
        let camera = MLNMapCamera(lookingAtCenter: coordinate,
                                 acrossDistance: 1000,
                                 pitch: 0,
                                 heading: 0)
        
        if let zoom = zoom {
            mapView.zoomLevel = zoom
        }
        
        mapView.setCamera(camera, animated: true)
    }
    
    func set(mapDelegate: MapInteractionDelegate?) {
        self.interactionDelegate = mapDelegate
    }
}
extension MapLibreWrapperModel {
    // MARK: - Marker Management
    
    func addMarker(_ marker: MapMarker) {
        markers.append(marker)
        addMarkerToMap(marker)
    }
    
    func removeMarker(withId id: String) {
        guard let index = markers.firstIndex(where: { $0.id == id }),
              let mapView = mapView else { return }
        
        // Remove from the map
        if let annotation = mapView.annotations?.first(where: { ($0 as? MLNPointAnnotation)?.identifier == id }) {
            mapView.removeAnnotation(annotation)
        }
        
        // Remove from our array
        markers.remove(at: index)
    }
    
    func clearAllMarkers() {
        guard let mapView = mapView else { return }
        
        // Remove all markers from the map
        for marker in markers {
            if let annotation = mapView.annotations?.first(where: { ($0 as? MLNPointAnnotation)?.identifier == marker.id }) {
                mapView.removeAnnotation(annotation)
            }
        }
        
        // Clear our array
        markers.removeAll()
    }
    
    private func addMarkerToMap(_ marker: MapMarker) {
        guard let mapView = mapView else { return }
        
        let point = MLNPointAnnotation()
        point.coordinate = marker.coordinate
        point.title = marker.title
        point.subtitle = marker.subtitle
        
        mapView.addAnnotation(point)
    }
    
    // MARK: - Marker Customization Delegate Methods
    
    public func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
        
        guard let pointAnnotation = annotation as? MLNPointAnnotation,
              let marker = markers.first(where: { $0.id == pointAnnotation.identifier }) else {
            return nil
        }

        let annotationView = MLNAnnotationView(annotation: annotation, reuseIdentifier: "marker")
        
        if let image = marker.image {
            annotationView.largeContentImage = image.withTintColor(marker.tintColor)
        }
        
        return annotationView
    }
}

extension MLNPointAnnotation {
    var identifier: String {
        "\(self.coordinate.latitude),\(self.coordinate.longitude)"
    }
}

extension MapLibreWrapperModel {
    func metersAcross(zoomLevel: Double, latitude: CLLocationDegrees, screenWidthPoints: CGFloat, scale: CGFloat = UIScreen.main.scale) -> Double {
        let tileSize: Double = 256.0 // pixels
        let earthCircumference: Double = 40_075_016.686  // in meters
        let zoomScale = pow(2.0, zoomLevel)

        // Pixel width of full world map at this zoom level
        let totalPixels = zoomScale * tileSize

        // Real-world meters per pixel at this latitude
        let metersPerPixel = (cos(latitude * Double.pi / 180) * earthCircumference) / totalPixels

        // Total width of map visible on screen in meters
        return metersPerPixel * Double(screenWidthPoints * scale)
    }
}
