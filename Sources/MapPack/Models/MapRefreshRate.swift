//
//  File.swift
//  IMap
//
//  Created by Muhammadjon Tohirov on 17/12/25.
//

import Foundation
import GoogleMaps
import MapLibre

public enum MapRefreshRate: Int, Equatable, Hashable, Sendable {
    case powerSafe
    case conservative
    case maximum
    
    var google: GMSFrameRate {
        switch self {
        case .powerSafe:
            return .powerSave
        case .conservative:
            return .conservative
        case .maximum:
            return .maximum
        }
    }
    
    var libre: MLNMapViewPreferredFramesPerSecond {
        switch self {
        case .powerSafe:
            return .lowPower
        case .conservative:
            return .default
        case .maximum:
            return .maximum
        }
    }
}
