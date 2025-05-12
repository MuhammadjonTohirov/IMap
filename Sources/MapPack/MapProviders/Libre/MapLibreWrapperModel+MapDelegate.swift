//
//  File.swift
//  IMap
//
//  Created by Muhammadjon Tohirov on 12/05/25.
//

import Foundation
import MapLibre

// MARK: - MLNMapViewDelegate Methods

extension MapLibreWrapperModel: MLNMapViewDelegate {
    
    public func mapView(_ mapView: MLNMapView, regionWillChangeAnimated animated: Bool) {
        Task { @MainActor in
            self.interactionDelegate?.mapDidStartMoving()
        }
    }
    
    public func mapView(_ mapView: MLNMapView, regionDidChangeAnimated animated: Bool) {
        Task { @MainActor in
            Logging.l("Map region did change animated: \(animated)")
            self.interactionDelegate?.mapDidEndDragging(
                at: .init(
                    latitude: mapView.centerCoordinate.latitude,
                    longitude: mapView.centerCoordinate.longitude
                )
            )
        }
    }
    
    // Handle tap on map (not on annotation)
    public func mapView(_ mapView: MLNMapView, didTapAtCoordinate coordinate: CLLocationCoordinate2D) {
        Task { @MainActor in
            self.interactionDelegate?.mapDidTap(at: coordinate)
        }
    }
    
    // Handle tap on annotation
    public func mapView(_ mapView: MLNMapView, didSelect annotation: MLNAnnotation) {
        Task { @MainActor in
            if let pointAnnotation = annotation as? MLNPointAnnotation {
                let handled = self.interactionDelegate?.mapDidTapMarker(id: pointAnnotation.identifier) ?? false
                
                // If the delegate handled the tap, deselect the annotation
                if handled {
                    mapView.deselectAnnotation(annotation, animated: true)
                }
            }
        }
    }
}
