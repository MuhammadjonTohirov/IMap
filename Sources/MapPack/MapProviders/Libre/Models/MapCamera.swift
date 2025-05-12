//
//  MapCamera.swift
//  LibreMap
//
//  Created by Muhammadjon Tohirov on 07/05/25.
//
// MapCamera.swift

import Foundation
import MapLibre

public struct MapCamera {
    public var camera: MLNMapCamera
    public var animate: Bool
    
    public init(camera: MLNMapCamera, animate: Bool = true) {
        self.camera = camera
        self.animate = animate
    }
    
    public static func lookingAt(center: CLLocationCoordinate2D,
                                 fromDistance distance: CLLocationDistance = 1000,
                                 pitch: CGFloat = 0,
                                 heading: CLLocationDirection = 0,
                                 animate: Bool = true) -> MapCamera {
        let camera = MLNMapCamera(lookingAtCenter: center,
                                  acrossDistance: distance,
                                  pitch: pitch,
                                  heading: heading)
        return MapCamera(camera: camera, animate: animate)
    }
    
    public static func following(coordinate: CLLocationCoordinate2D,
                                 distance: CLLocationDistance = 1000,
                                 pitch: CGFloat = 45,
                                 heading: CLLocationDirection = 0,
                                 animate: Bool = true) -> MapCamera {
        let camera = MLNMapCamera(lookingAtCenter: coordinate,
                                  acrossDistance: distance,
                                  pitch: pitch,
                                  heading: heading)
        return MapCamera(camera: camera, animate: animate)
    }
}
