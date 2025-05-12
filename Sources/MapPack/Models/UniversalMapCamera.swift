//
//  UniversalMapModels.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

// UniversalMap/Models/UniversalMapCamera.swift
import Foundation
import CoreLocation
import GoogleMaps
import MapLibre

/// A universal camera model that works with any map provider
public struct UniversalMapCamera {
    /// The center coordinate of the camera
    public var center: CLLocationCoordinate2D
    /// The zoom level
    public var zoom: Double
    /// The bearing/heading in degrees clockwise from north
    public var bearing: Double
    /// The viewing angle in degrees from the horizon (0 = looking straight down)
    public var pitch: Double
    /// Whether camera changes should be animated
    public var animate: Bool
    
    public init(
        center: CLLocationCoordinate2D,
        zoom: Double = 15,
        bearing: Double = 0,
        pitch: Double = 0,
        animate: Bool = true
    ) {
        self.center = center
        self.zoom = zoom
        self.bearing = bearing
        self.pitch = pitch
        self.animate = animate
    }
    
    /// Converts to a Google Maps camera position
    internal func toGMSCamera() -> GMapCamera {
        let position = GMSCameraPosition(
            target: center,
            zoom: Float(zoom),
            bearing: bearing,
            viewingAngle: pitch
        )
        
        return GMapCamera(
            camera: position,
            cameraUpdate: nil,
            animate: animate
        )
    }
    
    /// Converts to a MapLibre camera position
    internal func toMLNCamera() -> MapCamera {
        // MapLibre uses distance instead of zoom level, approximate conversion
        let distance = 1000.0 / pow(2, zoom - 13)
        
        return MapCamera.lookingAt(
            center: center,
            fromDistance: distance,
            pitch: CGFloat(pitch),
            heading: bearing,
            animate: animate
        )
    }
}
