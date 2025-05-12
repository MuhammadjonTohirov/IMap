//
//  RouteDataCoordinate.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

import Foundation
import CoreLocation

public enum RouteLineType {
    case carLine
    case walkLine
}

public struct RouteData {
    public var routings: [RouteDataCoordinate]
    public var distance, duration: Double
    
    public init(routings: [RouteDataCoordinate], distance: Double, duration: Double) {
        self.routings = routings
        self.distance = distance
        self.duration = duration
    }
}

public struct RouteDataCoordinate {
    public var lat: Double
    public var lng: Double
    public var lineType: RouteLineType = .carLine
    
    public var coordinate: CLLocationCoordinate2D {
        .init(latitude: lat, longitude: lng)
    }
    
    public init(lat: Double, lng: Double, lineType: RouteLineType) {
        self.lat = lat
        self.lng = lng
        self.lineType = lineType
    }
}
