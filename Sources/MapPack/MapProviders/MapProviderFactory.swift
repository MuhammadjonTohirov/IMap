//
//  MapProviderFactory.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

// UniversalMap/Providers/MapProviderFactory.swift
import Foundation

/// Represents the available map providers
public enum MapProvider: Identifiable, Equatable, Sendable {
    case google
    case mapLibre
    
    public var id: String {
        "\(self)"
    }
    
    public static func == (lhs: MapProvider, rhs: MapProvider) -> Bool {
        lhs.id == rhs.id
    }
}

/// Registry for map providers to support Open/Closed Principle
public final class MapProviderRegistry: @unchecked Sendable {
    public static let shared = MapProviderRegistry()
    
    private var builders: [String: () -> MapProviderProtocol] = [:]
    private let lock = NSLock()

    private init() {
        // Register default providers
        self.register(id: MapProvider.google.id) { GoogleMapsProvider() }
        self.register(id: MapProvider.mapLibre.id) { MapLibreProvider() }
    }
    
    public func register(id: String, builder: @escaping () -> MapProviderProtocol) {
        lock.lock()
        defer { lock.unlock() }
        builders[id] = builder
    }
    
    public func create(id: String) -> MapProviderProtocol {
        lock.lock()
        defer { lock.unlock() }
        
        guard let builder = builders[id] else {
            fatalError("MapProvider for id '\(id)' is not registered.")
        }
        return builder()
    }
}

/// Factory implementation for creating map providers
public struct MapProviderFactory: MapViewFactory {
    public static func createMapProvider(type: MapProvider) -> MapProviderProtocol {
        return MapProviderRegistry.shared.create(id: type.id)
    }
}
