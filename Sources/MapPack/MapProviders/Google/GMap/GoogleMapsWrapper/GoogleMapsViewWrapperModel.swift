//
//  GMapsViewWrapperModel.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

import Foundation
import GoogleMaps

public protocol UniversalMapInputProvider: AnyObject, Sendable {
    
}

public protocol GoogleMapsKeyProvider: UniversalMapInputProvider, AnyObject {
    var accessKey: String { get }
}

open class GoogleMapsViewWrapperModel: NSObject, ObservableObject {
    // Map view reference
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
    
    func focusTo(coordinate: CLLocationCoordinate2D, zoom: Float = 15, viewAngle: Double = 0) {
        mapView?.animate(to: GMSCameraPosition(target: coordinate, zoom: zoom, bearing: 0, viewingAngle: viewAngle))
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
            self.interactionDelegate?.mapDidEndDragging(at: .init(latitude: position.target.latitude, longitude: position.target.longitude))
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
        
        let style = GMSStrokeStyle.solidColor(lineColor)
        gmsPolyline.accessibilityLabel = polyline.id
        gmsPolyline.strokeColor = lineColor
        gmsPolyline.strokeWidth = polyline.width
        gmsPolyline.geodesic = polyline.geodesic
        
        gmsPolyline.spans = [
            GMSStyleSpan(style: style)
        ]
        
        return gmsPolyline
    }
}
