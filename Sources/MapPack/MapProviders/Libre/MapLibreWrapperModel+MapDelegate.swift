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
    public func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
        print("Map style finished loading")
        self.isMapLoaded = true
        
        // Add saved polylines to the map when style is loaded
        for polyline in savedPolylines {
            addPolylineToMap(polyline)
        }
    }
    
    public func mapView(_ mapView: MLNMapView, didUpdate userLocation: MLNUserLocation?) {
        if let location = userLocation?.location {
            self.userLocation = location
        }
    }
    
    public func mapView(_ mapView: MLNMapView, regionDidChangeAnimated animated: Bool) {
        Task { @MainActor in
            self.mapCenter = mapView.centerCoordinate
            self.zoomLevel = mapView.zoomLevel
        }
    }
}
