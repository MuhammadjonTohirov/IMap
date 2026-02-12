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
        let annotation = self.markers[marker.id]
        var hasChange: Bool = true
        
        if let annotation {
            hasChange = annotation.coordinate != marker.coordinate || annotation.rotation != marker.rotation
        }
        
        guard hasChange else {
            return
        }
        
        UIView.animate(withDuration: 1, delay: 0, options: .curveLinear) {
            annotation?.updatePosition(coordinate: marker.coordinate, heading: marker.rotation)
            if let annotation {
                self.applyMarkerViewRotation(annotation)
            }
        }
    }
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        if lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude {
            return true
        }
        return false
    }
}
