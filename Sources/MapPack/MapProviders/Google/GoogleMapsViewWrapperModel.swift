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
    // The actual Google map view
    public private(set) weak var mapView: GMSMapView?
    public private(set) weak var interactionDelegate: MapInteractionDelegate?
    
    // Data source: all known markers (by id)
    // These are NOT necessarily on the map; this is the full set you own.
    private(set) var allMarkers: [String: UniversalMarker] = [:]
    
    // Rendered markers currently on the map (by id)
    public private(set) var markers: [String: UniversalMarker] = [:]
    
    // Polylines currently on the map
    public private(set) var polylines: [String: GMSPolyline] = [:]
    
    func set(map: GMSMapView) {
        self.mapView = map
        // Initial refresh to render visible markers if any exist in the data source
        refreshVisibleMarkers()
    }
    
    @MainActor
    func set(inputProvider: any UniversalMapInputProvider) {
        guard let inputProvider = inputProvider as? GoogleMapsKeyProvider else { return }
        
        GMSServicesConfig.setupAPIKey(inputProvider.accessKey)
    }
    
    func set(mapDelegate: MapInteractionDelegate?) {
        self.interactionDelegate = mapDelegate
    }
    
    // MARK: - Camera helpers
    
    func focusTo(coordinate: CLLocationCoordinate2D, zoom: Float = 15, viewAngle: Double = 0, animate: Bool = true) {
        if animate {
            mapView?.animate(to: GMSCameraPosition(target: coordinate, zoom: zoom, bearing: 0, viewingAngle: viewAngle))
        } else {
            mapView?.camera = GMSCameraPosition(target: coordinate, zoom: zoom, bearing: 0, viewingAngle: viewAngle)
        }
        // After camera change, ensure markers reflect visibility
        refreshVisibleMarkers()
    }
    
    func focusTo(coordinates: [CLLocationCoordinate2D], padding: CGFloat, animated: Bool) {
        guard !coordinates.isEmpty else { return }
        
        var bounds = GMSCoordinateBounds()
        
        for coordinate in coordinates {
            bounds = bounds.includingCoordinate(coordinate)
        }
        
        let update = GMSCameraUpdate.fit(bounds, withPadding: padding)
        if animated {
            mapView?.animate(with: update)
        } else {
            mapView?.moveCamera(update)
        }
        refreshVisibleMarkers()
    }
    
    func focusTo(polyline id: String, edges: UIEdgeInsets, animate: Bool = true) {
        guard let pline = self.polylines[id], let path = pline.path else { return }
        if animate {
            mapView?.animate(with: GMSCameraUpdate.fit(.init(path: path), with: edges))
        } else {
            mapView?.moveCamera(.fit(.init(path: path), with: edges))
        }
        
        refreshVisibleMarkers()
    }
    
    func zoomOut(minLevel: Float = 10, shift: Double = 0.5) {
        guard let mapView = self.mapView else { return }
        
        let currentZoom = mapView.camera.zoom
        let targetZoom = minLevel
        
        let newZoom = max(currentZoom - Float(shift), targetZoom)

        UIView.animate(withDuration: 0.2) {
            self.mapView?.animate(toZoom: newZoom)
        }
        // After zoom out, refresh visibility
        refreshVisibleMarkers()
    }
    
    func onChangeColorScheme(_ scheme: ColorScheme) {
        switch scheme {
        case .dark:
            self.polylines.forEach { line in
                line.value.strokeColor = .white
            }
        case .light:
            self.polylines.forEach { line in
                line.value.strokeColor = .black
            }
        @unknown default:
            self.polylines.forEach { line in
                line.value.strokeColor = UIColor.systemBlue
            }
        }
    }
    
    // MARK: - Visibility management
    
    /// Computes the visible region and updates which markers are rendered.
    func refreshVisibleMarkers() {
        guard let mapView = mapView else { return }
        
        // Build bounds from current visible region
        let region = mapView.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(coordinate: region.nearLeft, coordinate: region.farRight)
            .includingCoordinate(region.nearRight)
            .includingCoordinate(region.farLeft)
        
        // Determine which ids should be visible
        let visibleIds: Set<String> = Set(
            allMarkers
                .lazy
                .filter { bounds.contains($0.value.position) }
                .map { $0.key }
        )
        
        // Currently rendered ids
        let renderedIds = Set(markers.keys)
        
        // Diff
        let toAdd = visibleIds.subtracting(renderedIds)
        let toRemove = renderedIds.subtracting(visibleIds)
        
        // Remove those that are no longer visible
        for id in toRemove {
            if let marker = markers[id] {
                marker.map = nil
                markers[id] = nil
            }
        }
        
        // Add newly visible markers
        for id in toAdd {
            if let marker = allMarkers[id] {
                marker.map = mapView
                markers[id] = marker
            }
        }
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
        // Update visible markers when camera stops moving
        refreshVisibleMarkers()
        
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
    // MARK: - Marker management (data source + visibility refresh)
    
    /// Adds or replaces a marker in the data source and refreshes visibility.
    func addMarker(id: String, marker: UniversalMarker) {
        // Keep canonical id on the marker for later lookups
        marker.accessibilityLabel = id
        allMarkers[id] = marker
        // Apply visibility rules immediately
        refreshVisibleMarkers()
    }
    
    /// Removes a marker from the data source and from the map if rendered.
    func removeMarker(id: String) {
        // Remove from data source
        allMarkers[id] = nil
        
        // If currently rendered, remove from map
        if let marker = markers[id] {
            marker.map = nil
            markers[id] = nil
        }
    }
    
    /// Removes all markers from data source and from the map.
    func removeAllMarkers() {
        // Clear rendered
        markers.values.forEach {
            $0.map = nil
        }
        markers.removeAll()
        // Clear data source
        allMarkers.removeAll()
    }
    
    /// Updates a marker's coordinate/heading if present in the data source, then refreshes visibility.
    func updateMarker(_ marker: UniversalMarker) {
        let id = marker.id
        // Update the data source entry if it exists
        if let existing = allMarkers[id] {
            existing.set(coordinate: marker.coordinate)
            existing.set(heading: marker.rotation)
        } else {
            // If not present, add it to the data source
            allMarkers[id] = marker
        }
        // Re-evaluate visibility after position changes
        refreshVisibleMarkers()
    }
    
    // MARK: - Polyline management
    
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
        gmsPolyline.strokeColor = lineColor
        gmsPolyline.strokeWidth = polyline.width
        gmsPolyline.geodesic = polyline.geodesic
        
        return gmsPolyline
    }
}
