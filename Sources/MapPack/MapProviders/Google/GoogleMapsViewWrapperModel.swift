//
//  GMapsViewWrapperModel.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

import Foundation
import GoogleMaps
import SwiftUI

public protocol UniversalMapInputProvider: AnyObject, Sendable {
    
}

public protocol GoogleMapsKeyProvider: UniversalMapInputProvider, AnyObject {
    var accessKey: String { get }
}

open class GoogleMapsViewWrapperModel: NSObject, ObservableObject {
    public private(set) weak var mapView: GMSMapView?
    public private(set) weak var interactionDelegate: MapInteractionDelegate?
    
    public private(set) var markers: [String: UniversalMarker] = [:]
    public private(set) var polylines: [String: GMSPolyline] = [:]
    
    func set(map: GMSMapView) {
        self.mapView = map
    }
    
    @MainActor
    func set(inputProvider: any UniversalMapInputProvider) {
        guard let inputProvider = inputProvider as? GoogleMapsKeyProvider else { return }
        
        GMSServicesConfig.setupAPIKey(inputProvider.accessKey)
    }
    
    func set(mapDelegate: MapInteractionDelegate?) {
        self.interactionDelegate = mapDelegate
    }
    
    func focusTo(coordinate: CLLocationCoordinate2D, zoom: Float = 15, viewAngle: Double = 0, animate: Bool = true) {
        if animate {
            mapView?.animate(to: GMSCameraPosition(target: coordinate, zoom: zoom, bearing: 0, viewingAngle: viewAngle))
        } else {
            mapView?.camera = GMSCameraPosition(target: coordinate, zoom: zoom, bearing: 0, viewingAngle: viewAngle)
        }
    }
    
    func focusTo(coordinates: [CLLocationCoordinate2D], padding: CGFloat, animated: Bool) {
        guard !coordinates.isEmpty else { return }
        
        var bounds = GMSCoordinateBounds()
        
        for coordinate in coordinates {
            bounds = bounds.includingCoordinate(coordinate)
        }
        
        let update = GMSCameraUpdate.fit(bounds, withPadding: padding)
        mapView?.animate(with: update)
    }
    
    func focusTo(polyline id: String, edges: UIEdgeInsets) {
        guard let pline = self.polylines[id], let path = pline.path else { return }
        mapView?.animate(with: GMSCameraUpdate.fit(.init(path: path), with: edges))
    }
    
    func zoomOut(minLevel: Float = 10, shift: Double = 0.5) {
        guard let mapView = self.mapView else { return }
        
        let currentZoom = mapView.camera.zoom
        let targetZoom = minLevel
        
        let newZoom = max(currentZoom - Float(shift), targetZoom)

        UIView.animate(withDuration: 0.2) {
            self.mapView?.animate(toZoom: newZoom)
        }
    }
    
    func onChangeColorScheme(_ scheme: ColorScheme) {
//        switch scheme {
//        case .dark:
//            self.polylines.forEach { line in
//                line.value.strokeColor = .white
//            }
//        case .light:
//            self.polylines.forEach { line in
//                line.value.strokeColor = .black
//            }
//        @unknown default:
//            self.polylines.forEach { line in
//                line.value.strokeColor = UIColor.systemBlue
//            }
//        }
    }
}

extension GoogleMapsViewWrapperModel: GMSMapViewDelegate {
    public func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        Task {@MainActor in
            if gesture {
                self.interactionDelegate?.mapDidStartDragging()
            } else {
                self.interactionDelegate?.mapDidStartMoving()
            }
        }
    }
    
    public func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        Task {@MainActor in
            let location: CLLocation = .init(
                coordinate: position.target,
                altitude: 0, horizontalAccuracy: 0,
                verticalAccuracy: 0,
                course: position.bearing,
                speed: 0,
                timestamp: Date()
            )
            self.interactionDelegate?.mapDidEndDragging(at: location)
        }
    }
}

public extension GoogleMapsViewWrapperModel {
    func addMarker(id: String, marker: UniversalMarker) {
        self.markers[id] = marker
        marker.map = self.mapView
    }
    
    func removeMarker(id: String) {
        guard let marker = self.markers[id] else {
            return
        }
        
        marker.map = nil
        self.markers[id] = nil
    }
    
    func removeAllMarkers() {
        self.markers.values.forEach {
            $0.map = nil
        }
        self.markers.removeAll()
    }
    
    func addPolyline(id: String, polyline: GMSPolyline) {
        self.polylines[id] = polyline
        polyline.map = self.mapView
    }
    
    func removePolyline(id: String) {
        guard let polyline = self.polylines[id] else {
            return
        }
        
        polyline.map = nil
        self.polylines[id] = nil
    }
    
    func removeAllPolylines() {
        self.polylines.values.forEach {
            $0.map = nil
        }
        self.polylines.removeAll()
    }
}

extension UniversalMapPolyline {
    func gmsPolyline(isCarLine: Bool = true) -> GMSPolyline {
        let polyline: UniversalMapPolyline = self
        let path = GMSMutablePath()

        for location in polyline.coordinates {
            path.add(location)
        }
        
        let gmsPolyline = GMSPolyline(path: path)
        
        let lineColor: UIColor = polyline.color
        
        gmsPolyline.accessibilityLabel = polyline.id
        gmsPolyline.strokeColor = lineColor.resolvedColor(with: .current)
        gmsPolyline.strokeWidth = polyline.width
        gmsPolyline.geodesic = polyline.geodesic
        
        return gmsPolyline
    }
}
