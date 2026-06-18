//
//  File.swift
//  IMap
//
//  Created by Muhammadjon Tohirov on 12/05/25.
//

import Foundation
import MapLibre
import UIKit

// MARK: - MLNMapViewDelegate Methods

extension MapLibreWrapperModel: MLNMapViewDelegate {
    
    public func mapView(_ mapView: MLNMapView, regionIsChangingWith reason: MLNCameraChangeReason) {
        refreshAllMarkerViewRotations()
    }
    
    public func mapView(_ mapView: MLNMapView, regionDidChangeAnimated animated: Bool) {
        Task { @MainActor in
            self.refreshAllMarkerViewRotations()
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
            switch reason {
            case .gesturePan, .gestureTilt, .gesturePinch, .gestureRotate, .gestureZoomIn, .gestureZoomOut:
                self.interactionDelegate?.mapDidStartDragging()
                
                if reason == .gestureRotate {
                    self.interactionDelegate?.mapDidRotate(to: mapView.centerCoordinate)
                }
            default:
                self.interactionDelegate?.mapDidStartMoving()
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
    
    public func mapView(_ mapView: MLNMapView, didUpdate userLocation: MLNUserLocation?) {
        guard let userLocation else {
            return
        }
        
        updateUserLocation(userLocation, in: mapView)
        
        // Propagate to interaction delegate if needed, though usually this is internal
        // self.interactionDelegate?.userLocationDidUpdate(location) 
    }
    
    public func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
        
        if annotation is MLNUserLocation {
            guard let image = userLocationImage else { return nil }
            
            let reuseId = "user-location-custom"
            
            // Try to reuse
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? UniversalUserLocationAnnotationView
            
            if view == nil {
                view = UniversalUserLocationAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            }
            
            view?.setup(image: image, scale: userLocationIconScale)
            view?.setCircleHidden(isAccuracyCircleHidden)

            // Initial update if location is known
            if let userLoc = annotation as? MLNUserLocation, let location = userLoc.location {
                if let view {
                    updateUserLocationView(
                        view,
                        location: location,
                        deviceHeading: userLoc.heading,
                        mapView: mapView
                    )
                }
            }

            return view
        }
        
        guard let pointAnnotation = annotation as? UniversalMarker,
              let marker = markers[pointAnnotation.id] else {
            Logging.l(tag: "MapLibre", "No marker found for \(annotation)")
            return nil
        }
        
        if let identifer = marker.reuseIdentifier {
            
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifer) ?? MLNAnnotationView(annotation: annotation, reuseIdentifier: identifer)
            if let _view = marker.view {
                view.subviews.forEach { $0.removeFromSuperview() }
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
        // Mark style as loaded and drain any pending camera operations
        Logging.l(tag: "MapLibre", "Map style loaded")
        
        // Restore Polylines
        self.savedPolylines.forEach { polyline in
            self.addPolylineToMap(polyline)
        }
        
        // Restore Buildings
        self.toggleBuildings(visible: self.isBuildingsEnabled)
        
        // Restore Markers (if missing)
        let existingMarkerIds = Set(mapView.annotations?.compactMap { ($0 as? UniversalMarker)?.id } ?? [])
        self.markers.values.forEach { marker in
            if !existingMarkerIds.contains(marker.id) {
                self.addMarkerToMap(marker)
            }
        }
    }
    
    public func mapViewDidFinishRenderingMap(_ mapView: MLNMapView, fullyRendered: Bool) {
        
        Logging.l(tag: "MapLibre", "Map rendered")
    }
    
    public func mapViewDidFinishLoadingMap(_ mapView: MLNMapView) {
        Logging.l(tag: "MapLibre", "Map loaded")

        self.isMapLoaded = true
        self.drainPendingActionsIfReady()
        Task { @MainActor in
            self.interactionDelegate?.mapDidLoaded()
        }
    }

    public func mapViewDidFailLoadingMap(_ mapView: MLNMapView, withError error: Error) {
        Logging.l(tag: "MapLibre", "Map failed to load with error: \(error.localizedDescription)")

        // If we haven't tried the fallback yet, attempt to load the backup style
        if !hasAttemptedFallback {
            Logging.l(tag: "MapLibre", "Attempting fallback to CartoDB style")
            set(hasAttemptedFallback: true)

            if let fallbackURL = URL(string: fallbackStyleURL) {
                mapView.styleURL = fallbackURL
            }
        } else {
            Logging.l(tag: "MapLibre", "Fallback style also failed. Cannot load map.")
        }
    }
}
