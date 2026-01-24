//
//  RouteTrackingManager.swift
//  UniversalMap
//
//  Created by Gemini on 24/01/26.
//

import Foundation
import CoreLocation
import MapKit

public enum RouteTrackingStatus {
    case onTrack(snappedLocation: CLLocationCoordinate2D, remainingPath: [CLLocationCoordinate2D])
    case outOfRoute
}

public class RouteTrackingManager {
    private let fullRouteCoordinates: [CLLocationCoordinate2D]
    private let threshold: CLLocationDistance
    
    // Cache the MKMapPoints for performance
    private let routePoints: [MKMapPoint]
    
    public init(routeCoordinates: [CLLocationCoordinate2D], threshold: CLLocationDistance = 30) {
        self.fullRouteCoordinates = routeCoordinates
        self.threshold = threshold
        self.routePoints = routeCoordinates.map { MKMapPoint($0) }
    }
    
    public func updateDriverLocation(_ location: CLLocationCoordinate2D) -> RouteTrackingStatus {
        let driverPoint = MKMapPoint(location)
        
        var minDistance: CLLocationDistance = .greatestFiniteMagnitude
        var closestPoint: MKMapPoint?
        var closestSegmentIndex: Int = -1
        
        // Iterate segments
        // If route has less than 2 points, we can't form a segment.
        if routePoints.count < 2 {
            // Handle single point or empty route?
            // If just 1 point, check distance to it.
            if let singlePoint = routePoints.first {
                let dist = driverPoint.distance(to: singlePoint)
                if dist <= threshold {
                    return .onTrack(snappedLocation: singlePoint.coordinate, remainingPath: fullRouteCoordinates)
                }
            }
            return .outOfRoute
        }
        
        for i in 0..<routePoints.count - 1 {
            let p1 = routePoints[i]
            let p2 = routePoints[i+1]
            
            let (point, distance) = distanceToSegment(p: driverPoint, p1: p1, p2: p2)
            
            if distance < minDistance {
                minDistance = distance
                closestPoint = point
                closestSegmentIndex = i
            }
        }
        
        guard let snappedPoint = closestPoint, minDistance <= threshold else {
            return .outOfRoute
        }
        
        let snappedCoordinate = snappedPoint.coordinate
        
        // Construct remaining polyline path
        // Start with snapped point
        var newCoordinates = [snappedCoordinate]
        
        // Add remaining points from the ORIGINAL polyline
        // If we snapped to segment i (between i and i+1), we include i+1 onwards
        if closestSegmentIndex + 1 < fullRouteCoordinates.count {
            newCoordinates.append(contentsOf: fullRouteCoordinates[(closestSegmentIndex + 1)...])
        }
        
        return .onTrack(snappedLocation: snappedCoordinate, remainingPath: newCoordinates)
    }
    
    private func distanceToSegment(p: MKMapPoint, p1: MKMapPoint, p2: MKMapPoint) -> (MKMapPoint, CLLocationDistance) {
        let x = p.x
        let y = p.y
        let x1 = p1.x
        let y1 = p1.y
        let x2 = p2.x
        let y2 = p2.y
        
        let dx = x2 - x1
        let dy = y2 - y1
        
        if dx == 0 && dy == 0 {
            // p1 and p2 are the same
            return (p1, p.distance(to: p1))
        }
        
        // Project p onto line containing p1-p2
        // t = ((p - p1) . (p2 - p1)) / |p2 - p1|^2
        let t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy)
        
        // Clamp t to segment [0, 1]
        let clampedT = max(0, min(1, t))
        
        let closestX = x1 + clampedT * dx
        let closestY = y1 + clampedT * dy
        let closest = MKMapPoint(x: closestX, y: closestY)
        
        return (closest, p.distance(to: closest))
    }
}
