//
//  MLNMapView+ZoomConversion.swift
//  IMap
//
//  Bidirectional conversion between a slippy-map zoom level and a camera
//  altitude (meters). Backed by MapLibre's own altitude⇄zoom math so results
//  stay consistent with the SDK's camera, instead of a hand-rolled formula
//  that can drift out of sync.
//

import CoreLocation
import MapLibre

extension MLNMapView {
    /// The camera altitude — meters perpendicular above the map — that
    /// corresponds to a slippy-map `zoom` level.
    ///
    /// Defaults to this view's current viewport size, camera pitch, and center
    /// latitude; override `pitch`/`latitude` to convert for a hypothetical
    /// camera. Inverse of ``zoom(forAltitude:pitch:latitude:)``.
    ///
    /// - Note: This is the camera's `altitude` (the value MapLibre's `altitude:`
    ///   initializer expects) — **not** `viewingDistance` (eye → center, which is
    ///   larger at non-zero pitch) and **not** `acrossDistance` (the horizontal
    ///   ground span used by the `acrossDistance:` initializer). The three are
    ///   different quantities; don't feed one where another is expected.
    func altitude(
        forZoom zoom: Double,
        pitch: CGFloat? = nil,
        latitude: CLLocationDegrees? = nil
    ) -> CLLocationDistance {
        MLNAltitudeForZoomLevel(
            zoom,
            pitch ?? camera.pitch,
            latitude ?? camera.centerCoordinate.latitude,
            bounds.size
        )
    }

    /// The slippy-map `zoom` level that corresponds to a camera `altitude`
    /// (meters perpendicular above the map — read it from `camera.altitude`).
    ///
    /// Defaults to this view's current viewport size, camera pitch, and center
    /// latitude. Inverse of ``altitude(forZoom:pitch:latitude:)``.
    func zoom(
        forAltitude altitude: CLLocationDistance,
        pitch: CGFloat? = nil,
        latitude: CLLocationDegrees? = nil
    ) -> Double {
        MLNZoomLevelForAltitude(
            altitude,
            pitch ?? camera.pitch,
            latitude ?? camera.centerCoordinate.latitude,
            bounds.size
        )
    }
}
