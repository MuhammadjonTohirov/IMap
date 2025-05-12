//
//  MapProviderFactory.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

// UniversalMap/Providers/MapProviderFactory.swift
import Foundation

/// Represents the available map providers
public enum MapProvider: Identifiable, Equatable {
    case google
    case mapLibre
    
    public var id: String {
        "\(self)"
    }
    
    public static func == (lhs: MapProvider, rhs: MapProvider) -> Bool {
        lhs.id == rhs.id
    }
}

/// Factory implementation for creating map providers
public struct MapProviderFactory: MapViewFactory {
    public static func createMapProvider(type: MapProvider) -> MapProviderProtocol {
        switch type {
        case .google:
            return GoogleMapsProvider()
        case .mapLibre:
            return MapLibreProvider()
        }
    }
}
