//
//  MapPolyline.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

import Foundation
import UIKit
import CoreLocation
import MapLibre

/// Model representing a polyline on the map
public struct MapPolyline: Identifiable {
    /// Unique identifier for the polyline
    public let id: String
    
    /// Optional title for the polyline
    public let title: String?
    
    /// Array of coordinates that form the polyline
    public let coordinates: [CLLocationCoordinate2D]
    
    /// Color of the polyline
    public let color: UIColor
    
    /// Width/thickness of the polyline
    public let width: CGFloat
    
    /// Initialize a new polyline
    /// - Parameters:
    ///   - id: Unique identifier, defaults to random UUID
    ///   - title: Optional title/name for the polyline
    ///   - coordinates: Array of coordinates that make up the polyline
    ///   - color: Color of the polyline, defaults to blue
    ///   - width: Width/thickness of the polyline, defaults to 3.0
    public init(
        id: String = UUID().uuidString,
        title: String? = nil,
        coordinates: [CLLocationCoordinate2D],
        color: UIColor = .blue,
        width: CGFloat = 3.0
    ) {
        self.id = id
        self.title = title
        self.coordinates = coordinates
        self.color = color
        self.width = width
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
    
    /// Get the bounding box of the polyline
    public var boundingBox: MLNCoordinateBounds? {
        guard !coordinates.isEmpty else { return nil }
        
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        
        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        
        let southwest = CLLocationCoordinate2D(latitude: minLat, longitude: minLon)
        let northeast = CLLocationCoordinate2D(latitude: maxLat, longitude: maxLon)
        
        return MLNCoordinateBounds(sw: southwest, ne: northeast)
    }
}
