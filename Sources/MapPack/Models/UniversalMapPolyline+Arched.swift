//
//  UniversalMapPolyline+Arched.swift
//  UniversalMap
//

import Foundation
import CoreLocation
import UIKit

public extension UniversalMapPolyline {

    /// Side of the arch relative to the directed segment A → B.
    enum ArchSide {
        /// Arch bulges to the left of the A → B direction.
        case left
        /// Arch bulges to the right of the A → B direction.
        case right
    }

    /// Builds a quadratic-Bézier arched polyline between two coordinates.
    ///
    /// The control point is placed perpendicular to the A → B segment at its
    /// midpoint, offset by `curvature * distance(A, B)`. Typical values:
    /// `0.15`–`0.30` for natural arches; larger produces a taller arch.
    ///
    /// - Parameters:
    ///   - id: Polyline identifier (defaults to a fresh UUID).
    ///   - from: Start coordinate (A).
    ///   - to: End coordinate (B).
    ///   - curvature: Arch height as a fraction of `|AB|`. Default `0.2`.
    ///   - side: Which side of A → B the arch bulges toward. Default `.left`.
    ///   - samples: Number of points sampled along the curve (incl. endpoints).
    ///              Higher = smoother. Default `48`.
    ///   - color: Stroke color.
    ///   - width: Stroke width in points.
    ///   - title: Optional title.
    /// - Returns: A polyline whose `coordinates` trace the arch.
    static func arched(
        id: String = UUID().uuidString,
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D,
        curvature: CGFloat = 0.2,
        side: ArchSide = .left,
        samples: Int = 48,
        color: UIColor = .blue,
        width: CGFloat = 3.0,
        title: String? = nil
    ) -> UniversalMapPolyline {
        let coordinates = archedCoordinates(
            from: from,
            to: to,
            curvature: curvature,
            side: side,
            samples: samples
        )
        return UniversalMapPolyline(
            id: id,
            coordinates: coordinates,
            color: color,
            width: width,
            geodesic: false,
            title: title
        )
    }

    /// Generates the sampled coordinates of a quadratic-Bézier arch between
    /// two points. Exposed separately so callers can post-process the points
    /// (animation, custom annotations) without constructing a polyline.
    static func archedCoordinates(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D,
        curvature: CGFloat = 0.2,
        side: ArchSide = .left,
        samples: Int = 48
    ) -> [CLLocationCoordinate2D] {
        let count = max(samples, 2)

        // Equirectangular projection around the midpoint latitude so a
        // "perpendicular" offset measured in degrees is visually perpendicular
        // on the rendered map (longitude degrees shrink with latitude).
        let midLat = (from.latitude + to.latitude) / 2.0
        let metersPerDegLat = 111_320.0
        let metersPerDegLon = 111_320.0 * cos(midLat * .pi / 180.0)

        let ax = 0.0
        let ay = 0.0
        let bx = (to.longitude - from.longitude) * metersPerDegLon
        let by = (to.latitude  - from.latitude)  * metersPerDegLat

        let dx = bx - ax
        let dy = by - ay
        let length = (dx * dx + dy * dy).squareRoot()
        guard length > 0 else { return [from, to] }

        // (-dy, dx) is the left-hand normal of (dx, dy); flip for `.right`.
        let signed: Double = (side == .left) ? 1.0 : -1.0
        let nx = -dy / length * signed
        let ny =  dx / length * signed

        let mx = (ax + bx) / 2.0
        let my = (ay + by) / 2.0
        let offset = Double(curvature) * length
        let cx = mx + nx * offset
        let cy = my + ny * offset

        var result: [CLLocationCoordinate2D] = []
        result.reserveCapacity(count)
        for i in 0..<count {
            let t = Double(i) / Double(count - 1)
            let omt = 1.0 - t
            // Quadratic Bézier: (1-t)²·A + 2(1-t)t·C + t²·B
            let x = omt * omt * ax + 2 * omt * t * cx + t * t * bx
            let y = omt * omt * ay + 2 * omt * t * cy + t * t * by
            let lon = from.longitude + x / metersPerDegLon
            let lat = from.latitude  + y / metersPerDegLat
            result.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        return result
    }
}
