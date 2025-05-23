//
//  File.swift
//  IMap
//
//  Created by applebro on 23/05/25.
//

import Foundation
import CoreLocation
import SwiftUI
import MapLibre

extension MapLibreWrapperModel {
    func updateMarker(_ marker: any UniversalMapMarkerProtocol) {
        Logging.l("Update marker")
        let annotation = self.markers[marker.id]
        UIView.animate(withDuration: 1, delay: 0, options: .curveLinear) {
            annotation?.set(coordinate: marker.coordinate)
        }
    }
}

//extension MapLibreWrapperModel {
//    
//    /// Properly update a marker without removing and re-adding
//    func updateMarker(_ marker: any UniversalMapMarkerProtocol) {
//        guard let universalMarker = marker as? UniversalMarker,
//              let mapView = mapView else {
//            Logging.l("Invalid marker or map view for update")
//            return
//        }
//        
//        // Check if marker exists in our markers dictionary
//        guard let existingMarker = markers[marker.id] else {
//            Logging.l("Marker not found, adding new marker: \(marker.id)")
//            addMarker(marker)
//            return
//        }
//        
//        // Update the existing marker's properties
//        existingMarker.set(coordinate: marker.coordinate)
//        
//        if let universalMarker = marker as? UniversalMarker {
//            existingMarker.set(heading: universalMarker.rotation)
//        }
//        
//        // Method 1: Direct coordinate update (most efficient)
//        updateMarkerCoordinate(existingMarker, newCoordinate: marker.coordinate)
//        
//        // Update our local reference
//        markers[marker.id] = existingMarker
//        
//        Logging.l("Updated marker position: \(marker.id) to \(marker.coordinate)")
//    }
//    
//    /// Update marker coordinate efficiently
//    private func updateMarkerCoordinate(_ marker: UniversalMarker, newCoordinate: CLLocationCoordinate2D) {
//        guard let mapView = mapView else { return }
//        
//        // Update the marker's coordinate property
//        marker.set(coordinate: newCoordinate)
//        
//        // For MapLibre, we need to remove and re-add the annotation to the map
//        // But we do it efficiently without recreating the marker object
//        mapView.removeAnnotation(marker)
//        mapView.addAnnotation(marker)
//        
//        // Alternative approach: Use MLNAnnotationView if available
//        if let annotationView = mapView.view(for: marker) {
//            // Update the annotation view's position
//            annotationView.center = mapView.convert(newCoordinate, toPointTo: mapView)
//        }
//    }
//    
//    /// Smooth animated marker update (for location tracking)
//    func updateMarkerAnimated(_ marker: any UniversalMapMarkerProtocol, duration: TimeInterval = 0.3) {
//        guard let universalMarker = marker as? UniversalMarker,
//              let mapView = mapView,
//              let existingMarker = markers[marker.id] else {
//            // Fallback to regular update
//            updateMarker(marker)
//            return
//        }
//        
//        let oldCoordinate = existingMarker.coordinate
//        let newCoordinate = marker.coordinate
//        
//        // Animate the position change
//        UIView.animate(withDuration: duration, animations: {
//            existingMarker.set(coordinate: newCoordinate)
//            
//            // Update heading if available
//            if let universalMarker = marker as? UniversalMarker {
//                existingMarker.set(heading: universalMarker.rotation)
//            }
//            
//            // Remove and re-add for MapLibre (unfortunately necessary)
//            mapView.removeAnnotation(existingMarker)
//            mapView.addAnnotation(existingMarker)
//        })
//        
//        // Update our local reference
//        markers[marker.id] = existingMarker
//        
//        Logging.l("Animated marker update: \(marker.id) from \(oldCoordinate) to \(newCoordinate)")
//    }
//    
//    /// Update multiple markers efficiently (batch update)
//    func updateMarkers(_ markers: [any UniversalMapMarkerProtocol]) {
//        guard !markers.isEmpty else { return }
//        
//        Logging.l("Batch updating \(markers.count) markers")
//        
//        for marker in markers {
//            updateMarker(marker)
//        }
//    }
//    
//    /// Update marker with custom properties
//    func updateMarker(_ marker: any UniversalMapMarkerProtocol,
//                     animated: Bool = false,
//                     duration: TimeInterval = 0.3) {
//        if animated {
//            updateMarkerAnimated(marker, duration: duration)
//        } else {
//            updateMarker(marker)
//        }
//    }
//}
//
//extension UniversalMarker {
//    
//    /// Update coordinate with optional animation
//    @discardableResult
//    func updateCoordinate(_ newCoordinate: CLLocationCoordinate2D, animated: Bool = false) -> Self {
//        if animated {
//            UIView.animate(withDuration: 0.3) {
//                self.set(coordinate: newCoordinate)
//            }
//        } else {
//            self.set(coordinate: newCoordinate)
//        }
//        return self
//    }
//    
//    /// Update heading with optional animation
//    @discardableResult
//    func updateHeading(_ newHeading: CLLocationDirection, animated: Bool = false) -> Self {
//        if animated {
//            UIView.animate(withDuration: 0.2) {
//                self.set(heading: newHeading)
//            }
//        } else {
//            self.set(heading: newHeading)
//        }
//        return self
//    }
//    
//    /// Update both coordinate and heading
//    @discardableResult
//    func updatePosition(coordinate: CLLocationCoordinate2D,
//                       heading: CLLocationDirection? = nil,
//                       animated: Bool = false) -> Self {
//        let duration: TimeInterval = animated ? 0.3 : 0
//        
//        if animated {
//            UIView.animate(withDuration: duration) {
//                self.set(coordinate: coordinate)
//                if let heading = heading {
//                    self.set(heading: heading)
//                }
//            }
//        } else {
//            self.set(coordinate: coordinate)
//            if let heading = heading {
//                self.set(heading: heading)
//            }
//        }
//        
//        return self
//    }
//}
