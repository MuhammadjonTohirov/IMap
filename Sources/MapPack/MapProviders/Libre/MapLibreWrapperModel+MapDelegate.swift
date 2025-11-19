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
    
    public func mapView(_ mapView: MLNMapView, regionWillChangeWith reason: MLNCameraChangeReason, animated: Bool) {
        Task { @MainActor in
            if reason == .programmatic {
                self.interactionDelegate?.mapDidStartMoving()
            } else {
                self.interactionDelegate?.mapDidStartDragging()
            }
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
            if let pointAnnotation = annotation as? UniversalMarker {
                let handled = self.interactionDelegate?.mapDidTapMarker(id: pointAnnotation.id) ?? false
                
                // If the delegate handled the tap, deselect the annotation
                if handled {
                    mapView.deselectAnnotation(annotation, animated: true)
                }
            }
        }
    }
    
    public func mapViewDidBecomeIdle(_ mapView: MLNMapView) {
        // TODO: Do something required
    }
    
    public func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
        
        guard let pointAnnotation = annotation as? UniversalMarker,
              let marker = markers[pointAnnotation.id] else {
            Logging.l(tag: "MapLibre", "No marker found for \(annotation)")
            return nil
        }
        
        if let identifer = marker.reuseIdentifier {
            
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifer) ?? MLNAnnotationView(annotation: annotation, reuseIdentifier: identifer)
            if let _view = marker.view {
                view.addSubview(_view)
            }
            Logging.l(tag: "MapLibre", "Annotation view reused for \(identifer)")
            view.layer.zPosition = CGFloat(marker.zIndex)
            return view
        }
        
        let annotationView = MLNAnnotationView(annotation: annotation, reuseIdentifier: "marker")
        annotationView.layer.zPosition = CGFloat(marker.zIndex)
        Logging.l(tag: "MapLibre", "Annotation view created")
        return annotationView
    }
    
    public func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
        self.interactionDelegate?.mapDidLoaded()
    }
}
