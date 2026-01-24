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
    public func addPolylineToMap(_ polyline: MapPolyline) {
        guard let mapView = mapView, let style = mapView.style else {
            // If style isn't loaded yet, we'll add it in didFinishLoading
            return
        }
        
        // Create polyline from coordinates
        let mlnPolyline = MLNPolyline(coordinates: polyline.coordinates, count: UInt(polyline.coordinates.count))
        
        // Create shape source
        let source = MLNShapeSource(identifier: "polyline-source-\(polyline.id)", shape: mlnPolyline, options: nil)
        
        // Create line style layer
        let lineLayer = MLNLineStyleLayer(identifier: "polyline-layer-\(polyline.id)", source: source)
        
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
    public func addPolyline(id: String? = nil, coordinates: [CLLocationCoordinate2D], title: String? = nil, color: UIColor = .blue, width: CGFloat = 3.0) -> MapPolyline {
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
        addPolylineToMap(polyline)
        
        return polyline
    }
    
    public func updatePolyline(id: String, coordinates: [CLLocationCoordinate2D]) {
        guard let index = savedPolylines.firstIndex(where: { $0.id == id }) else { return }
        
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
        
        // Update the shape source on the map
        guard let style = mapView?.style,
              let source = style.source(withIdentifier: "polyline-source-\(id)") as? MLNShapeSource else {
            // If source missing, try full add
            addPolylineToMap(newPolyline)
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
