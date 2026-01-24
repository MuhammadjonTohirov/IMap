//
//  MapLibreWrapperModel+Polyline.swift
//  LibreMap
//
//  Created by Muhammadjon Tohirov on 07/05/25.
//
// MapLibreWrapperModel+Polyline.swift

import Foundation
import MapLibre
import CoreLocation
import UIKit

extension MapLibreWrapperModel {
    
    // MARK: - Polyline Drawing Methods
    
    /// Start polyline drawing mode
    public func startPolylineDrawing() {
        isDrawingPolyline = true
        drawingCoordinates.removeAll()
        
        // Remove any existing temporary drawing layers
        cleanupTemporaryDrawing()
    }
    
    /// Add a point to the current polyline being drawn
    /// - Parameter coordinate: Location to add to the polyline
    public func addPointToPolyline(coordinate: CLLocationCoordinate2D) {
        guard isDrawingPolyline else { return }
        
        // Add the coordinate
        drawingCoordinates.append(coordinate)
        
        // Update the visualization if we have at least 2 points
        if drawingCoordinates.count >= 2 {
            updateDrawingVisualization()
        }
    }
    
    /// Update the visual display of the polyline being drawn
    private func updateDrawingVisualization() {
        guard let mapView = mapView, let style = mapView.style else { return }
        
        // Remove existing temporary drawing if it exists
        cleanupTemporaryDrawing()
        
        // Create a polyline from the coordinates array
        let polyline = MLNPolyline(coordinates: drawingCoordinates, count: UInt(drawingCoordinates.count))
        
        // Create or update shape source
        let source = MLNShapeSource(identifier: tempPolylineSourceID, shape: polyline, options: nil)
        style.addSource(source)
        
        // Create line style layer
        let lineLayer = MLNLineStyleLayer(identifier: tempPolylineLayerID, source: source)
        
        // Set the line color using NSExpression
        lineLayer.lineColor = NSExpression(forConstantValue: UIColor.red)
        
        // Set the line width using NSExpression
        lineLayer.lineWidth = NSExpression(forConstantValue: 4.0)
        
        // Set the line cap and join style
        lineLayer.lineCap = NSExpression(forConstantValue: "round")
        lineLayer.lineJoin = NSExpression(forConstantValue: "round")
        
        // Set line dash pattern for drawing mode (dashed line)
        lineLayer.lineDashPattern = NSExpression(forConstantValue: [2, 2])
        
        // Add the layer
        style.addLayer(lineLayer)
    }
    
    /// Complete drawing a polyline and save it permanently
    /// - Parameters:
    ///   - title: Optional title for the polyline
    ///   - color: Color of the saved polyline
    ///   - width: Width of the saved polyline
    /// - Returns: True if a valid polyline was saved
    @discardableResult
    public func finishPolylineDrawing(title: String? = nil, color: UIColor = .blue, width: CGFloat = 3.0) -> Bool {
        // Check if we have a valid polyline
        guard isDrawingPolyline, drawingCoordinates.count >= 2 else {
            isDrawingPolyline = false
            drawingCoordinates.removeAll()
            cleanupTemporaryDrawing()
            return false
        }
        
        // Create a permanent saved polyline
        let polyline = MapPolyline(
            id: UUID().uuidString,
            title: title,
            coordinates: drawingCoordinates,
            color: color,
            width: width
        )
        
        // Add to saved polylines
        savedPolylines.append(polyline)
        
        // Add to map as a permanent layer
        addPolylineToMap(polyline)
        
        // Reset drawing state
        isDrawingPolyline = false
        drawingCoordinates.removeAll()
        
        // Clean up the temporary drawing layer
        cleanupTemporaryDrawing()
        
        return true
    }
    
    /// Cancel polyline drawing without saving
    public func cancelPolylineDrawing() {
        isDrawingPolyline = false
        drawingCoordinates.removeAll()
        cleanupTemporaryDrawing()
    }
    
    /// Clean up temporary drawing sources and layers
    private func cleanupTemporaryDrawing() {
        guard let style = mapView?.style else { return }
        
        if let layer = style.layer(withIdentifier: tempPolylineLayerID) {
            style.removeLayer(layer)
        }
        
        if let source = style.source(withIdentifier: tempPolylineSourceID) {
            style.removeSource(source)
        }
    }
    
    // MARK: - Polyline Management Methods
    
    /// Add a predefined polyline to the map
    /// - Parameter polyline: MapPolyline object to add
    public func addPolylineToMap(_ polyline: MapPolyline, animated: Bool = false) {
        guard let mapView = mapView, let style = mapView.style else {
            // If style isn't loaded yet, we'll add it in didFinishLoading
            return
        }
        
        // Cancel existing animation
        activePolylineAnimations[polyline.id]?.invalidate()
        activePolylineAnimations[polyline.id] = nil
        
        let sourceId = "polyline-source-\(polyline.id)"
        let layerId = "polyline-layer-\(polyline.id)"
        
        // Clean up previous layers if any
        if let layer = style.layer(withIdentifier: layerId) { style.removeLayer(layer) }
        if let source = style.source(withIdentifier: sourceId) { style.removeSource(source) }
        
        // Determine initial coordinates
        let initialCoords: [CLLocationCoordinate2D]
        if animated && polyline.coordinates.count > 0 {
            initialCoords = [polyline.coordinates[0]]
        } else {
            initialCoords = polyline.coordinates
        }
        
        // Create polyline from coordinates
        let mlnPolyline = MLNPolyline(coordinates: initialCoords, count: UInt(initialCoords.count))
        
        // Create shape source
        let source = MLNShapeSource(identifier: sourceId, shape: mlnPolyline, options: nil)
        
        // Create line style layer
        let lineLayer = MLNLineStyleLayer(identifier: layerId, source: source)
        
        // Set the line color using NSExpression
        lineLayer.lineColor = NSExpression(forConstantValue: polyline.color)
        
        // Set the line width using NSExpression
        lineLayer.lineWidth = NSExpression(forConstantValue: polyline.width)
        
        // Set the line cap and join style
        lineLayer.lineCap = NSExpression(forConstantValue: "round")
        lineLayer.lineJoin = NSExpression(forConstantValue: "round")
        
        // Add source and layer to map
        style.addSource(source)
        style.addLayer(lineLayer)
        
        if animated && polyline.coordinates.count > 1 {
            animatePolylineDrawing(id: polyline.id, fullCoordinates: polyline.coordinates)
        }
    }
    
    private func animatePolylineDrawing(id: String, fullCoordinates: [CLLocationCoordinate2D]) {
        let count = fullCoordinates.count
        var currentIndex: Int = 1
        
        let duration: TimeInterval = 1.0
        let fps: Double = 60
        let interval = 1.0 / fps
        let totalSteps = duration * fps
        let pointsPerStep = max(1, Int(ceil(Double(count) / totalSteps)))
        
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            // Check existence
            guard let style = self.mapView?.style,
                  let source = style.source(withIdentifier: "polyline-source-\(id)") as? MLNShapeSource else {
                timer.invalidate()
                self.activePolylineAnimations[id] = nil
                return
            }
            
            let endIndex = min(currentIndex + pointsPerStep, count)
            let currentCoords = Array(fullCoordinates[0..<endIndex])
            
            let shape = MLNPolyline(coordinates: currentCoords, count: UInt(currentCoords.count))
            source.shape = shape
            
            currentIndex = endIndex
            
            if currentIndex >= count {
                timer.invalidate()
                self.activePolylineAnimations[id] = nil
            }
        }
        self.activePolylineAnimations[id] = timer
    }
    
    /// Add a polyline from raw coordinates
    /// - Parameters:
    ///   - id: Optional ID for the polyline. If nil, a UUID will be generated.
    ///   - coordinates: Array of coordinates for the polyline
    ///   - title: Optional title
    ///   - color: Color of the polyline
    ///   - width: Width of the line
    /// - Returns: The created polyline object
    @discardableResult
    public func addPolyline(id: String? = nil, coordinates: [CLLocationCoordinate2D], title: String? = nil, color: UIColor = .blue, width: CGFloat = 3.0, animated: Bool = false) -> MapPolyline {
        let polylineId = id ?? UUID().uuidString
        
        // Remove existing if any (to prevent duplicates if same ID passed)
        removePolyline(id: polylineId)
        
        // Create a new polyline object
        let polyline = MapPolyline(
            id: polylineId,
            title: title,
            coordinates: coordinates,
            color: color,
            width: width
        )
        
        // Add to saved polylines
        savedPolylines.append(polyline)
        
        // Add to map
        addPolylineToMap(polyline, animated: animated)
        
        return polyline
    }
    
    public func updatePolyline(id: String, coordinates: [CLLocationCoordinate2D], animated: Bool = false) {
        guard let index = savedPolylines.firstIndex(where: { $0.id == id }) else { return }
        
        // Cancel existing animation
        activePolylineAnimations[id]?.invalidate()
        activePolylineAnimations[id] = nil
        
        // Create updated struct (since MapPolyline is immutable)
        let old = savedPolylines[index]
        let newPolyline = MapPolyline(
            id: old.id,
            title: old.title,
            coordinates: coordinates,
            color: old.color,
            width: old.width
        )
        savedPolylines[index] = newPolyline
        
        if animated {
            addPolylineToMap(newPolyline, animated: true)
            return
        }
        
        // Update the shape source on the map
        guard let style = mapView?.style,
              let source = style.source(withIdentifier: "polyline-source-\(id)") as? MLNShapeSource else {
            // If source missing, try full add
            addPolylineToMap(newPolyline, animated: false)
            return
        }
        
        let mlnPolyline = MLNPolyline(coordinates: coordinates, count: UInt(coordinates.count))
        source.shape = mlnPolyline
    }
    
    public func updatePolyline(id: String, color: UIColor, width: CGFloat) {
        guard let index = savedPolylines.firstIndex(where: { $0.id == id }) else { return }
        
        let old = savedPolylines[index]
        let newPolyline = MapPolyline(
            id: old.id,
            title: old.title,
            coordinates: old.coordinates,
            color: color,
            width: width
        )
        savedPolylines[index] = newPolyline
        
        guard let style = mapView?.style,
              let layer = style.layer(withIdentifier: "polyline-layer-\(id)") as? MLNLineStyleLayer else {
             return
        }
        
        layer.lineColor = NSExpression(forConstantValue: color)
        layer.lineWidth = NSExpression(forConstantValue: width)
    }
    
    /// Remove a polyline from the map
    /// - Parameter polylineId: ID of the polyline to remove
    public func removePolyline(id polylineId: String) {
        activePolylineAnimations[polylineId]?.invalidate()
        activePolylineAnimations[polylineId] = nil
        
        guard let style = mapView?.style,
              let index = savedPolylines.firstIndex(where: { $0.id == polylineId }) else {
            return
        }
        
        // Remove the layer and source from the map
        if let layer = style.layer(withIdentifier: "polyline-layer-\(polylineId)") {
            style.removeLayer(layer)
        }
        
        if let source = style.source(withIdentifier: "polyline-source-\(polylineId)") {
            style.removeSource(source)
        }
        
        // Remove from the array
        savedPolylines.remove(at: index)
    }
    
    /// Clear all polylines from the map
    public func clearAllPolylines() {
        guard let style = mapView?.style else { return }
        
        // Remove all polylines
        for polyline in savedPolylines {
            if let layer = style.layer(withIdentifier: "polyline-layer-\(polyline.id)") {
                style.removeLayer(layer)
            }
            
            if let source = style.source(withIdentifier: "polyline-source-\(polyline.id)") {
                style.removeSource(source)
            }
        }
        
        // Clear the array
        savedPolylines.removeAll()
    }
    
    /// Fit the map view to show a specific polyline
    /// - Parameters:
    ///   - polylineId: ID of the polyline to focus on
    ///   - padding: Edge padding to apply
    ///   - animated: Whether to animate the camera change
    public func focusOnPolyline(id polylineId: String, padding: UIEdgeInsets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: Bool = true) {
        guard let polyline = savedPolylines.first(where: { $0.id == polylineId }),
              let bounds = polyline.boundingBox else {
            return
        }
        
        Task { @MainActor in
            await mapView?.setVisibleCoordinateBounds(bounds, edgePadding: padding, animated: animated)
        }
    }
}

extension MapLibreWrapperModel {
    func updateCarMarker(position: CLLocationCoordinate2D, heading: Double) {
//        guard let mapView = mapView else { return }
//        
//        let carMarkerId = "navigation-car-marker"
//        
//        if let existingMarker = markers.first(where: { $0.id == carMarkerId }) {
//            removeMarker(withId: carMarkerId)
//        }
//        
//        let carImage = UIImage(systemName: "car.fill")?.withTintColor(.blue)
        
        // Add new car marker
//        let carMarker = LibreMarker(
//            id: carMarkerId,
//            coordinate: position,
//            title: "Current Location",
//            annotationView: nil,
//            tintColor: .blue
//        )
//        
//        addMarker(carMarker)
    }
}
