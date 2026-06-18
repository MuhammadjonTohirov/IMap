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
        guard let annotation = self.markers[marker.id] else {
            addMarker(marker)
            return
        }

        annotation.updatePosition(coordinate: marker.coordinate, heading: marker.worldHeading)
        self.applyMarkerViewRotation(annotation)
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
