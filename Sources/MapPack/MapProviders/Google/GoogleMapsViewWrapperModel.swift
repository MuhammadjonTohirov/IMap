//
//  GMapsViewWrapperModel.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

import Foundation
import GoogleMaps
import SwiftUI

public protocol UniversalMapConfigProtocol: Sendable {
    var lightStyle: String {get set}
    var darkStyle: String {get set}
}

public protocol GoogleMapsConfigProtocol: UniversalMapConfigProtocol {
    var accessKey: String { get }
}

open class GoogleMapsViewWrapperModel: NSObject, ObservableObject {
    // The actual Google map view
    var activePolylineAnimations: [String: Timer] = [:]

    public private(set) weak var mapView: GMSMapView?
    public private(set) weak var interactionDelegate: MapInteractionDelegate?
    
    // Data source: all known markers (by id)
    // These are NOT necessarily on the map; this is the full set you own.
    public private(set) var allMarkers: [String: UniversalMarker] = [:]
    
    // Rendered markers currently on the map (by id)
    public private(set) var markers: [String: UniversalMarker] = [:]
    
    // Polylines currently on the map
    public private(set) var polylines: [String: GMSPolyline] = [:]
    
    public private(set) var config: GoogleMapsConfigProtocol?
    
    private var didAppear: Bool = false
    
    func onAppear() {
        if didAppear {
            return
        }
        
        didAppear = true
        self.interactionDelegate?.mapDidLoaded()
    }
    
    @MainActor
    func set(preferredRefreshRate: MapRefreshRate) {
        self.mapView?.preferredFrameRate = preferredRefreshRate.google
    }
    
    func set(map: GMSMapView) {
        self.mapView = map
        // Initial refresh to render visible markers if any exist in the data source
        refreshVisibleMarkers()
    }
    
    @MainActor
    func set(config: any UniversalMapConfigProtocol) {
        guard let _config = config as? GoogleMapsConfigProtocol else { return }
        self.config = _config
        GMSServicesConfig.setupAPIKey(_config.accessKey)
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
        
        switch scheme {
        case .dark:
            self.mapView?.mapStyle = try? .init(jsonString: self.config?.darkStyle ?? GoogleDarkMapStyle().source)
        default:
            self.mapView?.mapStyle = try? .init(jsonString: self.config?.lightStyle ?? GoogleLightMapStyle().source)
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
    
    public func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        // Update UserLocationMarkerView if visible
        // We know the ID is USER_LOCATION_MARKER, but the WrapperModel doesn't know that constant.
        // We can iterate or just look for markers with that view type.
        // Efficiency: If we have 1000 markers, iterating is bad.
        // Ideally we should know which marker is the user location.
        // But for now, let's look up by ID "USER_LOCATION_MARKER" if we can access that constant or just hardcode it
        // OR better: check visible markers that have tracksViewChanges = true
        
        if let userMarker = markers["USER_LOCATION_MARKER"], 
           let view = userMarker.iconView as? UserLocationMarkerView {
            view.updateZoom(position.zoom)
        }
    }
    
    public func mapViewDidFinishTileRendering(_ mapView: GMSMapView) {
        // TODO: Handle tile rendering
    }
    
    public func mapViewSnapshotReady(_ mapView: GMSMapView) {
        // TODO: Snapshot ready
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
        
    func addPolyline(id: String, polyline: GMSPolyline, animated: Bool = false) {
        // Cancel existing animation
        activePolylineAnimations[id]?.invalidate()
        activePolylineAnimations[id] = nil
        
        // Remove existing if any to avoid duplicates/leaks
        if let existing = self.polylines[id] {
            existing.map = nil
        }
        
        self.polylines[id] = polyline
        
        if animated, let path = polyline.path, path.count() > 1 {
            let fullPath = path
            let emptyPath = GMSMutablePath()
            // Start with first point
            emptyPath.add(fullPath.coordinate(at: 0))
            
            polyline.path = emptyPath
            polyline.map = self.mapView
            
            animatePolylineDrawing(id: id, polyline: polyline, fullPath: fullPath)
        } else {
            polyline.map = self.mapView
        }
    }
    
    private func animatePolylineDrawing(id: String, polyline: GMSPolyline, fullPath: GMSPath) {
        let count = fullPath.count()
        var currentIndex: UInt = 1
        // Animation config
        let duration: TimeInterval = 1.0
        let fps: Double = 60
        let interval = 1.0 / fps
        let totalSteps = duration * fps
        let pointsPerStep = max(1, UInt(ceil(Double(count) / totalSteps)))
        
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            // Check if polyline still exists and is the same instance
            guard let currentPolyline = self.polylines[id], currentPolyline == polyline else {
                timer.invalidate()
                self.activePolylineAnimations[id] = nil
                return
            }
            
            guard let path = polyline.path else { return }
            
            let currentPath = GMSMutablePath(path: path)
            
            let endIndex = min(currentIndex + pointsPerStep, count)
            for i in currentIndex..<endIndex {
                currentPath.add(fullPath.coordinate(at: i))
            }
            
            polyline.path = currentPath
            currentIndex = endIndex
            
            if currentIndex >= count {
                timer.invalidate()
                self.activePolylineAnimations[id] = nil
            }
        }
        
        activePolylineAnimations[id] = timer
    }
    
    func updatePolyline(id: String, coordinates: [CLLocationCoordinate2D], animated: Bool = false) {
        guard let polyline = self.polylines[id] else { return }
        
        // Cancel active animation if any, and set full path immediately if not animating
        activePolylineAnimations[id]?.invalidate()
        activePolylineAnimations[id] = nil
        
        let path = GMSMutablePath()
        coordinates.forEach { path.add($0) }
        
        if animated {
            // Reuse animation logic for updates? 
            // The user requested animation for "drawing".
            // If we update coordinates, we treat it as a redraw from start if animated is true.
            let emptyPath = GMSMutablePath()
            if coordinates.count > 0 {
                emptyPath.add(coordinates[0])
            }
            polyline.path = emptyPath
            animatePolylineDrawing(id: id, polyline: polyline, fullPath: path)
        } else {
            polyline.path = path
        }
    }
    
    func updatePolyline(id: String, with newPolyline: UniversalMapPolyline, animated: Bool = false) {
        // If it doesn't exist, we can add it, or just return.
        guard let polyline = self.polylines[id] else {
            // Fallback to add
            addPolyline(id: id, polyline: newPolyline.gmsPolyline(), animated: animated)
            return
        }
        
        activePolylineAnimations[id]?.invalidate()
        activePolylineAnimations[id] = nil
        
        let path = GMSMutablePath()
        newPolyline.coordinates.forEach { path.add($0) }
        
        polyline.strokeColor = newPolyline.color
        polyline.strokeWidth = newPolyline.width
        polyline.geodesic = newPolyline.geodesic
        
        if animated {
            let emptyPath = GMSMutablePath()
            if newPolyline.coordinates.count > 0 {
                emptyPath.add(newPolyline.coordinates[0])
            }
            polyline.path = emptyPath
            animatePolylineDrawing(id: id, polyline: polyline, fullPath: path)
        } else {
            polyline.path = path
        }
    }
    
    func removePolyline(id: String) {
        activePolylineAnimations[id]?.invalidate()
        activePolylineAnimations[id] = nil
        
        guard let polyline = self.polylines[id] else {
            return
        }
        
        polyline.map = nil
        self.polylines[id] = nil
    }
    
    func removeAllPolylines() {
        activePolylineAnimations.values.forEach { $0.invalidate() }
        activePolylineAnimations.removeAll()
        
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
