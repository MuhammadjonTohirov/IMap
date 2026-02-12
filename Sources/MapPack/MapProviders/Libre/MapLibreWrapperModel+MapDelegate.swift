//
//  File.swift
//  IMap
//
//  Created by Muhammadjon Tohirov on 12/05/25.
//

import Foundation
import MapLibre
import UIKit

class UniversalUserLocationAnnotationView: MLNUserLocationAnnotationView {
    private let circleView = UIView()
    private var iconView: UIImageView?
    private var iconSize: CGSize = .zero
    
    private var lastAccuracy: CLLocationAccuracy = 0
    private var lastLatitude: CLLocationDegrees = 0
    private var isCircleHidden: Bool = false
    
    override init(annotation: MLNAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        clipsToBounds = false
        circleView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        circleView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.6).cgColor
        circleView.layer.borderWidth = 1
        circleView.isUserInteractionEnabled = false
        addSubview(circleView)
        sendSubviewToBack(circleView)
    }
    
    func setup(image: UIImage, scale: CGFloat) {
        if iconView == nil {
            let iv = UIImageView(image: image)
            iv.contentMode = .scaleAspectFit
            addSubview(iv)
            iconView = iv
        } else {
            iconView?.image = image
        }
        
        self.iconSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        iconView?.frame = CGRect(origin: .zero, size: iconSize)
        
        // Initial layout
        self.frame = iconView?.frame ?? .zero
        iconView?.center = CGPoint(x: frame.width/2, y: frame.height/2)
    }
    
    func setCircleHidden(_ hidden: Bool) {
        self.isCircleHidden = hidden
        self.circleView.isHidden = hidden
    }
    
    func update(accuracy: CLLocationAccuracy, zoom: Double, latitude: CLLocationDegrees) {
        self.lastAccuracy = accuracy
        self.lastLatitude = latitude
        updateLayout(zoom: zoom)
    }
    
    func updateZoom(_ zoom: Double) {
        updateLayout(zoom: zoom)
    }
    
    private func updateLayout(zoom: Double) {
        if isCircleHidden { return }
        
        // Calculate radius in points
        // metersPerPoint = 40075016.686 * cos(lat * pi / 180) / (256 * 2^zoom)
        // Simplified:
        let metersPerPoint = 156543.03392 * cos(lastLatitude * .pi / 180) / pow(2, zoom)
        let radiusPoints = CGFloat(lastAccuracy / metersPerPoint)
        
        // Diameter
        let diameter = radiusPoints * 2
        
        // We do NOT resize self.frame (the annotation view itself) to avoid flickering.
        // The view stays the size of the icon. The circle grows outside it (clipsToBounds = false).
        
        let center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let circleFrame = CGRect(
            x: center.x - diameter / 2,
            y: center.y - diameter / 2,
            width: diameter,
            height: diameter
        )
        
        if circleView.frame != circleFrame {
             circleView.frame = circleFrame
             circleView.layer.cornerRadius = diameter / 2
        }
    }
}

// MARK: - MLNMapViewDelegate Methods

extension MapLibreWrapperModel: MLNMapViewDelegate {
    
    public func mapView(_ mapView: MLNMapView, regionIsChangingWith reason: MLNCameraChangeReason) {
         if let userLocationAnnotation = mapView.userLocation,
           let view = mapView.view(for: userLocationAnnotation) as? UniversalUserLocationAnnotationView {
             view.updateZoom(mapView.zoomLevel)
        }
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
        guard let location = userLocation?.location,
              let annotation = userLocation,
              let view = mapView.view(for: annotation) as? UniversalUserLocationAnnotationView else {
            return
        }
        
        view.update(accuracy: location.horizontalAccuracy, zoom: mapView.zoomLevel, latitude: location.coordinate.latitude)
        
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
            
            // Initial update if location is known
            if let userLoc = annotation as? MLNUserLocation, let location = userLoc.location {
                view?.update(accuracy: location.horizontalAccuracy, zoom: mapView.zoomLevel, latitude: location.coordinate.latitude)
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
        self.interactionDelegate?.mapDidLoaded()
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
