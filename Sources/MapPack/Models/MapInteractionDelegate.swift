//
//  UniversalMapInteractionDelegate.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

// UniversalMap/Models/MapInteractionDelegate.swift
import Foundation
import CoreLocation

/// Protocol for handling map interaction events
public protocol MapInteractionDelegate: AnyObject {
    /// Called when the map starts being dragged by the user
    func mapDidStartDragging()
    
    /// Called when the map starts moving (programmatically or by user)
    func mapDidStartMoving()
    
    /// Called when the map stops being dragged and becomes idle
    func mapDidEndDragging(at location: CLLocation)
    
    /// Called when a marker is tapped
    func mapDidTapMarker(id: String) -> Bool
    
    /// Called when the map is tapped (not on a marker)
    func mapDidTap(at coordinate: CLLocationCoordinate2D)
}

// Default implementation
public extension MapInteractionDelegate {
    func mapDidStartDragging() {}
    func mapDidStartMoving() {}
    func mapDidEndDragging(at location: CLLocation) {}
    func mapDidTapMarker(id: String) -> Bool { false }
    func mapDidTap(at coordinate: CLLocationCoordinate2D) {}
}
