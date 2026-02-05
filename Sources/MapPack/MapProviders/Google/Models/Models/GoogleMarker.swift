//
//  UniversalMapMarker.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

// UniversalMap/Models/UniversalMapMarker.swift
import Foundation
import CoreLocation
import UIKit
import GoogleMaps

public protocol UniversalMapMarkerProtocol: Identifiable, Sendable, Hashable {
    var id: String { get }
    var coordinate: CLLocationCoordinate2D { get }
    var rotation: CLLocationDirection { get }
}

extension CLLocationCoordinate2D {
    var identifier: String {
        "\(latitude),\(longitude)"
    }
}
