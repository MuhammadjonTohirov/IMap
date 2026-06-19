import CoreLocation
import MapKit

public final class NavigationRouteTrackingManager {
    private let fullRouteCoordinates: [CLLocationCoordinate2D]
    private let threshold: CLLocationDistance
    private let routePoints: [MKMapPoint]
    private let cumulativeDistances: [CLLocationDistance]
    private let totalDistance: CLLocationDistance
    private var lastRouteProgress: CLLocationDistance = 0

    public init(routeCoordinates: [CLLocationCoordinate2D], threshold: CLLocationDistance = 30) {
        self.fullRouteCoordinates = routeCoordinates
        self.threshold = threshold
        self.routePoints = routeCoordinates.map(MKMapPoint.init)

        var cumulative: [CLLocationDistance] = [0]
        var total: CLLocationDistance = 0
        if routePoints.count > 1 {
            for index in 1..<routePoints.count {
                total += routePoints[index - 1].distance(to: routePoints[index])
                cumulative.append(total)
            }
        }
        self.cumulativeDistances = cumulative
        self.totalDistance = total
    }

    public func updateDriverLocation(_ location: CLLocationCoordinate2D) -> NavigationRouteTrackingStatus {
        let driverPoint = MKMapPoint(location)

        var closestCandidate: RouteProjectionCandidate?
        var forwardCandidate: RouteProjectionCandidate?

        if routePoints.count < 2 {
            if let singlePoint = routePoints.first {
                let distance = driverPoint.distance(to: singlePoint)
                if distance <= threshold {
                    return .onTrack(snappedLocation: singlePoint.coordinate, remainingPath: fullRouteCoordinates)
                }
            }
            return .outOfRoute
        }

        for index in 0..<(routePoints.count - 1) {
            let p1 = routePoints[index]
            let p2 = routePoints[index + 1]

            let projection = distanceToSegment(p: driverPoint, p1: p1, p2: p2)
            let segmentLength = cumulativeDistances[index + 1] - cumulativeDistances[index]
            let progress = cumulativeDistances[index] + (segmentLength * projection.t)
            let candidate = RouteProjectionCandidate(
                point: projection.point,
                distance: projection.distance,
                segmentIndex: index,
                progress: progress
            )

            if closestCandidate.map({ candidate.distance < $0.distance }) ?? true {
                closestCandidate = candidate
            }

            if candidate.distance <= threshold,
               candidate.progress >= lastRouteProgress - 0.5,
               forwardCandidate.map({ candidate.distance < $0.distance }) ?? true {
                forwardCandidate = candidate
            }
        }

        guard let candidate = forwardCandidate ?? closestCandidate,
              candidate.distance <= threshold else {
            return .outOfRoute
        }

        let progress = max(lastRouteProgress, candidate.progress)
        lastRouteProgress = progress

        let snappedPoint = point(at: progress) ?? candidate.point
        let snappedCoordinate = snappedPoint.coordinate
        let segmentIndex = segmentStartIndex(for: progress) ?? candidate.segmentIndex

        var newCoordinates = [snappedCoordinate]
        if segmentIndex + 1 < fullRouteCoordinates.count {
            newCoordinates.append(contentsOf: fullRouteCoordinates[(segmentIndex + 1)...])
        }

        return .onTrack(snappedLocation: snappedCoordinate, remainingPath: newCoordinates)
    }

    private func distanceToSegment(
        p: MKMapPoint,
        p1: MKMapPoint,
        p2: MKMapPoint
    ) -> (point: MKMapPoint, distance: CLLocationDistance, t: Double) {
        let x = p.x
        let y = p.y
        let x1 = p1.x
        let y1 = p1.y
        let x2 = p2.x
        let y2 = p2.y

        let dx = x2 - x1
        let dy = y2 - y1

        if dx == 0, dy == 0 {
            return (p1, p.distance(to: p1), 0)
        }

        let t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy)
        let clampedT = max(0, min(1, t))

        let closestX = x1 + clampedT * dx
        let closestY = y1 + clampedT * dy
        let closest = MKMapPoint(x: closestX, y: closestY)

        return (closest, p.distance(to: closest), clampedT)
    }

    private func point(at progress: CLLocationDistance) -> MKMapPoint? {
        guard routePoints.count > 1 else {
            return routePoints.first
        }

        if progress <= 0 {
            return routePoints[0]
        }

        if progress >= totalDistance {
            return routePoints[routePoints.count - 1]
        }

        guard let index = segmentStartIndex(for: progress) else {
            return nil
        }

        let start = routePoints[index]
        let end = routePoints[index + 1]
        let startDistance = cumulativeDistances[index]
        let endDistance = cumulativeDistances[index + 1]
        let segmentLength = endDistance - startDistance
        let t = segmentLength > 0 ? (progress - startDistance) / segmentLength : 0

        return MKMapPoint(
            x: start.x + ((end.x - start.x) * t),
            y: start.y + ((end.y - start.y) * t)
        )
    }

    private func segmentStartIndex(for progress: CLLocationDistance) -> Int? {
        guard cumulativeDistances.count > 1 else {
            return nil
        }

        if progress >= totalDistance {
            return max(0, cumulativeDistances.count - 2)
        }

        for index in 0..<(cumulativeDistances.count - 1) {
            if progress >= cumulativeDistances[index],
               progress <= cumulativeDistances[index + 1] {
                return index
            }
        }

        return nil
    }
}

private struct RouteProjectionCandidate {
    let point: MKMapPoint
    let distance: CLLocationDistance
    let segmentIndex: Int
    let progress: CLLocationDistance
}
