//
//  UniversalMapPolyline.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//


// UniversalMap/Models/UniversalMapPolyline.swift
import Foundation
import CoreLocation
import UIKit
import GoogleMaps
import MapLibre

/// A universal polyline model that works with any map provider
public struct UniversalMapPolyline: Identifiable {
    /// Unique identifier for the polyline
    public let id: String
    /// Array of coordinates that form the polyline
    public var coordinates: [CLLocationCoordinate2D]
    /// Color of the polyline
    public var color: UIColor
    /// Width/thickness of the polyline
    public var width: CGFloat
    /// Whether to follow the curvature of the Earth
    public var geodesic: Bool
    /// Optional title for the polyline
    public var title: String?
    
    public init(
        id: String = UUID().uuidString,
        coordinates: [CLLocationCoordinate2D],
        color: UIColor = .blue,
        width: CGFloat = 3.0,
        geodesic: Bool = true,
        title: String? = nil
    ) {
        self.id = id
        self.coordinates = coordinates
        self.color = color
        self.width = width
        self.geodesic = geodesic
        self.title = title
    }
    
    /// Converts route coordinates to a polyline
    public static func fromRouteCoordinates(_ routeCoords: [RouteDataCoordinate]) -> UniversalMapPolyline {
        let coordinates = routeCoords.map { $0.coordinate }
        return UniversalMapPolyline(coordinates: coordinates)
    }
    
    /// Calculate the total distance of the polyline in meters
    public var distance: CLLocationDistance {
        guard coordinates.count > 1 else { return 0 }
        
        var totalDistance: CLLocationDistance = 0
        for i in 0..<coordinates.count-1 {
            let start = CLLocation(latitude: coordinates[i].latitude, longitude: coordinates[i].longitude)
            let end = CLLocation(latitude: coordinates[i+1].latitude, longitude: coordinates[i+1].longitude)
            totalDistance += start.distance(from: end)
        }
        
        return totalDistance
    }
    
    /// Converts to a MapLibre polyline
    internal func toMapLibrePolyline() -> MapPolyline {
        
        return MapPolyline(
            id: id,
            title: title,
            coordinates: coordinates,
            color: color,
            width: width
        )
    }
}
