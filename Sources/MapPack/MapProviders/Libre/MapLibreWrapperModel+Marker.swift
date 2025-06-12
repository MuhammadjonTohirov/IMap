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
