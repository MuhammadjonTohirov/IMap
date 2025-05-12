//
//  MapViewFactory.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

// UniversalMap/Protocols/MapViewFactory.swift
import SwiftUI

/// Factory for creating map provider instances
public protocol MapViewFactory: Sendable {
    /// Create a map provider based on the specified type
    static func createMapProvider(type: MapProvider) -> MapProviderProtocol
}
