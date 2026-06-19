//
//  Array+Coordinates.swift
//  IMap
//
//  Shared geometry helpers for coordinate paths.
//

import CoreLocation

extension Array where Element == CLLocationCoordinate2D {
    /// Total great-circle length of the path in meters.
    ///
    /// Computed without allocating a `CLLocation` per vertex (which the naive
    /// `CLLocation.distance(from:)` loop would), so it is cheap enough to call
    /// on long routes.
    var pathDistance: CLLocationDistance {
        guard count > 1 else { return 0 }

        var total: CLLocationDistance = 0
        for index in 1..<count {
            total += self[index - 1].greatCircleDistance(to: self[index])
        }
        return total
    }
}

extension CLLocationCoordinate2D {
    /// Great-circle (haversine) distance in meters — allocation-free, unlike
    /// `CLLocation.distance(from:)` which heap-allocates two `CLLocation` objects.
    func greatCircleDistance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        // Mean Earth radius (meters), matching the value Core Location uses.
        let earthRadius: CLLocationDistance = 6_372_797.560856

        let lat1 = latitude * .pi / 180
        let lat2 = other.latitude * .pi / 180
        let deltaLat = (other.latitude - latitude) * .pi / 180
        let deltaLon = (other.longitude - longitude) * .pi / 180

        let a = sin(deltaLat / 2) * sin(deltaLat / 2)
            + cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c
    }
}
