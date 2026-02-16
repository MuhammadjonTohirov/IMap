import CoreLocation
import MapKit

public final class NavigationRouteTrackingManager {
    private let fullRouteCoordinates: [CLLocationCoordinate2D]
    private let threshold: CLLocationDistance
    private let routePoints: [MKMapPoint]

    public init(routeCoordinates: [CLLocationCoordinate2D], threshold: CLLocationDistance = 30) {
        self.fullRouteCoordinates = routeCoordinates
        self.threshold = threshold
        self.routePoints = routeCoordinates.map(MKMapPoint.init)
    }

    public func updateDriverLocation(_ location: CLLocationCoordinate2D) -> NavigationRouteTrackingStatus {
        let driverPoint = MKMapPoint(location)

        var minDistance: CLLocationDistance = .greatestFiniteMagnitude
        var closestPoint: MKMapPoint?
        var closestSegmentIndex: Int = -1

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

            let (point, distance) = distanceToSegment(p: driverPoint, p1: p1, p2: p2)

            if distance < minDistance {
                minDistance = distance
                closestPoint = point
                closestSegmentIndex = index
            }
        }

        guard let snappedPoint = closestPoint, minDistance <= threshold else {
            return .outOfRoute
        }

        let snappedCoordinate = snappedPoint.coordinate
        var newCoordinates = [snappedCoordinate]

        if closestSegmentIndex + 1 < fullRouteCoordinates.count {
            newCoordinates.append(contentsOf: fullRouteCoordinates[(closestSegmentIndex + 1)...])
        }

        return .onTrack(snappedLocation: snappedCoordinate, remainingPath: newCoordinates)
    }

    private func distanceToSegment(
        p: MKMapPoint,
        p1: MKMapPoint,
        p2: MKMapPoint
    ) -> (MKMapPoint, CLLocationDistance) {
        let x = p.x
        let y = p.y
        let x1 = p1.x
        let y1 = p1.y
        let x2 = p2.x
        let y2 = p2.y

        let dx = x2 - x1
        let dy = y2 - y1

        if dx == 0, dy == 0 {
            return (p1, p.distance(to: p1))
        }

        let t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy)
        let clampedT = max(0, min(1, t))

        let closestX = x1 + clampedT * dx
        let closestY = y1 + clampedT * dy
        let closest = MKMapPoint(x: closestX, y: closestY)

        return (closest, p.distance(to: closest))
    }
}
