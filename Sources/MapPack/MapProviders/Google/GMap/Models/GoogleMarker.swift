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

public protocol UniversalMapMarkerProtocol: Identifiable {
    var id: String { get }
    var coordinate: CLLocationCoordinate2D { get }
}

extension CLLocationCoordinate2D {
    var identifier: String {
        "\(latitude),\(longitude)"
    }
}
