//
//  MapLibreConfigProtocol.swift
//  IMap
//

/// Configuration values that apply specifically to the MapLibre provider.
public protocol MapLibreConfigProtocol: UniversalMapConfigProtocol {
    /// Whether the user can change the camera pitch with MapLibre's pitch gesture.
    ///
    /// This does not prevent programmatic camera updates from setting a pitch.
    var isPitchEnabled: Bool { get }
}
