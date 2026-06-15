import CoreLocation
import MapKit

public struct NavigationRouteProgressGeometry {
    private let route: [CLLocationCoordinate2D]
    private let routePoints: [MKMapPoint]
    private let cumulativeDistances: [CLLocationDistance]
    public let totalDistance: CLLocationDistance

    public init(route: [CLLocationCoordinate2D]) {
        // The route is immutable, so compact consecutive duplicate points once here
        // rather than on every per-frame `remainingRoute(from:)` call.
        let compacted = Self.compactConsecutive(route)
        let points = compacted.map(MKMapPoint.init)

        var cumulative: [CLLocationDistance] = [0]
        var total: CLLocationDistance = 0

        if points.count > 1 {
            for index in 1..<points.count {
                total += points[index - 1].distance(to: points[index])
                cumulative.append(total)
            }
        }

        self.route = compacted
        self.routePoints = points
        self.cumulativeDistances = cumulative
        self.totalDistance = total
    }

    public var isValid: Bool {
        route.count >= 2
    }

    public func clamp(progress: CLLocationDistance) -> CLLocationDistance {
        max(0, min(totalDistance, progress))
    }

    public func progress(of coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        guard routePoints.count > 1 else { return 0 }

        let point = MKMapPoint(coordinate)
        var bestProgress: CLLocationDistance = 0
        var bestDistance: CLLocationDistance = .greatestFiniteMagnitude

        for index in 0..<(routePoints.count - 1) {
            let start = routePoints[index]
            let end = routePoints[index + 1]
            let projection = project(point: point, start: start, end: end)

            if projection.distance < bestDistance {
                bestDistance = projection.distance
                let segmentLength = cumulativeDistances[index + 1] - cumulativeDistances[index]
                bestProgress = cumulativeDistances[index] + (segmentLength * projection.t)
            }
        }

        return clamp(progress: bestProgress)
    }

    public func progress(fromRemainingPath remainingPath: [CLLocationCoordinate2D]) -> CLLocationDistance? {
        guard !remainingPath.isEmpty else { return nil }

        var remainingDistance: CLLocationDistance = 0
        if remainingPath.count > 1 {
            for index in 1..<remainingPath.count {
                remainingDistance += remainingPath[index - 1].distance(to: remainingPath[index])
            }
        }

        return clamp(progress: totalDistance - remainingDistance)
    }

    public func coordinate(at progress: CLLocationDistance) -> CLLocationCoordinate2D {
        guard let first = route.first else {
            return .init()
        }

        guard route.count > 1 else {
            return first
        }

        let clamped = clamp(progress: progress)

        if clamped <= 0 {
            return route[0]
        }

        if clamped >= totalDistance {
            return route[route.count - 1]
        }

        let index = segmentStartIndex(forClampedProgress: clamped)
        return interpolatedCoordinate(in: index, clampedProgress: clamped)
    }

    public func heading(at progress: CLLocationDistance, fallback: CLLocationDirection) -> CLLocationDirection {
        guard route.count > 1 else { return fallback }

        let clamped = clamp(progress: progress)
        let lead: CLLocationDistance = 1.0

        let fromProgress = max(0, clamped - lead)
        let toProgress = min(totalDistance, clamped + lead)

        let fromCoordinate = coordinate(at: fromProgress)
        let toCoordinate = coordinate(at: toProgress)

        return fromCoordinate.bearing(to: toCoordinate) ?? fallback
    }

    public func remainingRoute(from progress: CLLocationDistance) -> [CLLocationCoordinate2D] {
        guard !route.isEmpty else { return [] }

        guard route.count > 1 else { return [route[0]] }

        let clamped = clamp(progress: progress)

        if clamped <= 0 {
            return route
        }

        if clamped >= totalDistance {
            return [route[route.count - 1]]
        }

        let index = segmentStartIndex(forClampedProgress: clamped)
        let head = interpolatedCoordinate(in: index, clampedProgress: clamped)
        let tail = route[(index + 1)...]

        // The stored route is already compacted, so the only possible duplicate is the
        // interpolated head sitting on top of the next vertex.
        if let next = tail.first, head.distance(to: next) <= 0.05 {
            return Array(tail)
        }

        var output: [CLLocationCoordinate2D] = [head]
        output.append(contentsOf: tail)
        return output
    }

    // MARK: - Segment lookup

    /// Binary-searches the sorted `cumulativeDistances` for the segment that contains
    /// `clamped`, returning the index of the segment's start vertex.
    ///
    /// - Precondition: `0 < clamped < totalDistance` (callers handle the endpoints),
    ///   which guarantees a valid segment exists.
    private func segmentStartIndex(forClampedProgress clamped: CLLocationDistance) -> Int {
        var low = 1
        var high = cumulativeDistances.count - 1

        while low < high {
            let mid = (low + high) / 2
            if cumulativeDistances[mid] >= clamped {
                high = mid
            } else {
                low = mid + 1
            }
        }

        return low - 1
    }

    private func interpolatedCoordinate(
        in index: Int,
        clampedProgress clamped: CLLocationDistance
    ) -> CLLocationCoordinate2D {
        let startDistance = cumulativeDistances[index]
        let endDistance = cumulativeDistances[index + 1]
        let segmentLength = endDistance - startDistance
        let t = segmentLength > 0 ? (clamped - startDistance) / segmentLength : 0
        return route[index].interpolated(to: route[index + 1], t: t)
    }

    private static func compactConsecutive(
        _ coordinates: [CLLocationCoordinate2D]
    ) -> [CLLocationCoordinate2D] {
        guard !coordinates.isEmpty else { return [] }

        var compacted: [CLLocationCoordinate2D] = []
        compacted.reserveCapacity(coordinates.count)
        var lastPoint: MKMapPoint?

        for coordinate in coordinates {
            let point = MKMapPoint(coordinate)
            if let last = lastPoint, last.distance(to: point) <= 0.05 {
                continue
            }
            compacted.append(coordinate)
            lastPoint = point
        }

        return compacted
    }

    private func project(
        point: MKMapPoint,
        start: MKMapPoint,
        end: MKMapPoint
    ) -> (distance: CLLocationDistance, t: Double) {
        let dx = end.x - start.x
        let dy = end.y - start.y

        if dx == 0, dy == 0 {
            return (point.distance(to: start), 0)
        }

        let t = (
            ((point.x - start.x) * dx) + ((point.y - start.y) * dy)
        ) / ((dx * dx) + (dy * dy))

        let clampedT = max(0, min(1, t))
        let projected = MKMapPoint(
            x: start.x + (clampedT * dx),
            y: start.y + (clampedT * dy)
        )

        return (point.distance(to: projected), clampedT)
    }
}

private extension CLLocationCoordinate2D {
    /// Planar distance via `MKMapPoint`, avoiding the two `CLLocation` allocations a
    /// great-circle `CLLocation.distance(from:)` would incur on every call.
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        MKMapPoint(self).distance(to: MKMapPoint(other))
    }

    func interpolated(to other: CLLocationCoordinate2D, t: Double) -> CLLocationCoordinate2D {
        .init(
            latitude: latitude + ((other.latitude - latitude) * t),
            longitude: longitude + ((other.longitude - longitude) * t)
        )
    }

    func bearing(to other: CLLocationCoordinate2D) -> CLLocationDirection? {
        let lat1 = latitude * .pi / 180
        let lon1 = longitude * .pi / 180
        let lat2 = other.latitude * .pi / 180
        let lon2 = other.longitude * .pi / 180

        let deltaLon = lon2 - lon1
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)

        guard x != 0 || y != 0 else { return nil }

        var heading = atan2(y, x) * 180 / .pi
        heading = heading.truncatingRemainder(dividingBy: 360)
        if heading < 0 { heading += 360 }
        return heading
    }
}
