import CoreLocation
import Foundation
import MapboxCoreNavigation
import MapboxDirections

/// Errors raised while adapting a geometry-only route for turn-by-turn navigation.
public enum MapNavigationRouteError: Error, Equatable, LocalizedError {
    case insufficientCoordinates
    case invalidCoordinate(index: Int)
    case zeroLengthRoute
    case invalidDistance
    case invalidExpectedTravelTime

    public var errorDescription: String? {
        switch self {
        case .insufficientCoordinates:
            return "A navigation route requires at least two coordinates."
        case let .invalidCoordinate(index):
            return "The navigation route contains an invalid coordinate at index \(index)."
        case .zeroLengthRoute:
            return "The navigation route must have a non-zero length."
        case .invalidDistance:
            return "The navigation route distance must be finite and greater than zero."
        case .invalidExpectedTravelTime:
            return "The navigation route travel time must be finite and greater than zero."
        }
    }
}

/// An ordered route that can be presented by IMap's turn-by-turn navigation UI.
///
/// This adapter is intended for services that already return route geometry, distance,
/// and duration but do not return the complete Mapbox Directions response schema.
/// It deliberately creates only generic continuation steps and an arrival step. Route
/// snapping, progress, ETA, arrival detection, and the navigation camera remain available,
/// while real maneuver instructions require a Directions-compatible route response.
public final class MapNavigationRoute {
    public let coordinates: [CLLocationCoordinate2D]
    public let distance: CLLocationDistance
    public let expectedTravelTime: TimeInterval

    let platformRoute: Route

    public init(
        coordinates: [CLLocationCoordinate2D],
        distance: CLLocationDistance,
        expectedTravelTime: TimeInterval
    ) throws {
        guard coordinates.count >= 2 else {
            throw MapNavigationRouteError.insufficientCoordinates
        }

        for (index, coordinate) in coordinates.enumerated() {
            guard coordinate.latitude.isFinite,
                  coordinate.longitude.isFinite,
                  CLLocationCoordinate2DIsValid(coordinate) else {
                throw MapNavigationRouteError.invalidCoordinate(index: index)
            }
        }

        guard distance.isFinite, distance > 0 else {
            throw MapNavigationRouteError.invalidDistance
        }
        guard expectedTravelTime.isFinite, expectedTravelTime > 0 else {
            throw MapNavigationRouteError.invalidExpectedTravelTime
        }

        let compactedCoordinates = Self.compactConsecutiveCoordinates(coordinates)
        guard compactedCoordinates.count >= 2 else {
            throw MapNavigationRouteError.zeroLengthRoute
        }

        self.coordinates = compactedCoordinates
        self.distance = distance
        self.expectedTravelTime = expectedTravelTime
        self.platformRoute = Self.makePlatformRoute(
            coordinates: compactedCoordinates,
            distance: distance,
            expectedTravelTime: expectedTravelTime
        )
    }

    private static func compactConsecutiveCoordinates(
        _ coordinates: [CLLocationCoordinate2D]
    ) -> [CLLocationCoordinate2D] {
        var result: [CLLocationCoordinate2D] = []
        result.reserveCapacity(coordinates.count)

        for coordinate in coordinates {
            guard let previous = result.last else {
                result.append(coordinate)
                continue
            }

            let previousLocation = CLLocation(
                latitude: previous.latitude,
                longitude: previous.longitude
            )
            let currentLocation = CLLocation(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            if previousLocation.distance(from: currentLocation) > 0.05 {
                result.append(coordinate)
            }
        }

        return result
    }

    private static func makePlatformRoute(
        coordinates: [CLLocationCoordinate2D],
        distance: CLLocationDistance,
        expectedTravelTime: TimeInterval
    ) -> Route {
        let origin = coordinates[0]
        let destination = coordinates[coordinates.count - 1]
        let options = NavigationRouteOptions(
            coordinates: [origin, destination],
            profileIdentifier: .automobile
        )
        options.shapeFormat = .geoJSON
        options.includesAlternativeRoutes = false
        options.attributeOptions = []
        options.includesSpokenInstructions = false
        options.includesVisualInstructions = false

        let routeGeometry = lineString(coordinates)
        let startBearing = bearing(from: coordinates[0], to: coordinates[1])
        let endBearing = bearing(
            from: coordinates[coordinates.count - 2],
            to: coordinates[coordinates.count - 1]
        )

        let continueStep: [String: Any] = [
            "distance": distance,
            "duration": expectedTravelTime,
            "driving_side": "right",
            "geometry": routeGeometry,
            "maneuver": [
                "bearing_after": startBearing,
                "bearing_before": startBearing,
                "instruction": "Continue along the route",
                "location": geoJSONCoordinate(origin),
                "modifier": "straight",
                "type": "depart"
            ],
            "mode": "driving",
            "name": ""
        ]

        let destinationGeometry = lineString([destination, destination])
        let terminalContinuationStep: [String: Any] = [
            "distance": 0.0,
            "duration": 0.0,
            "driving_side": "right",
            "geometry": destinationGeometry,
            "maneuver": [
                "bearing_after": endBearing,
                "bearing_before": endBearing,
                "instruction": "Continue to your destination",
                "location": geoJSONCoordinate(destination),
                "modifier": "straight",
                "type": "continue"
            ],
            "mode": "driving",
            "name": ""
        ]

        let arrivalStep: [String: Any] = [
            "distance": 0.0,
            "duration": 0.0,
            "driving_side": "right",
            "geometry": destinationGeometry,
            "maneuver": [
                "bearing_after": endBearing,
                "bearing_before": endBearing,
                "instruction": "You have arrived at your destination",
                "location": geoJSONCoordinate(destination),
                "modifier": "straight",
                "type": "arrive"
            ],
            "mode": "driving",
            "name": ""
        ]

        let routeJSON: [String: Any] = [
            "distance": distance,
            "duration": expectedTravelTime,
            "geometry": routeGeometry,
            "legs": [[
                "distance": distance,
                "duration": expectedTravelTime,
                // MapLibre Navigation 4.1 treats a leg with only one remaining step
                // and no voice instructions as already arrived. The zero-distance
                // continuation keeps geometry-only routes active until the device
                // actually reaches the destination.
                "steps": [continueStep, terminalContinuationStep, arrivalStep],
                "summary": ""
            ]]
        ]

        return Route(
            json: routeJSON,
            waypoints: options.waypoints,
            options: options
        )
    }

    private static func lineString(
        _ coordinates: [CLLocationCoordinate2D]
    ) -> [String: Any] {
        [
            "coordinates": coordinates.map(geoJSONCoordinate),
            "type": "LineString"
        ]
    }

    private static func geoJSONCoordinate(
        _ coordinate: CLLocationCoordinate2D
    ) -> [Double] {
        [coordinate.longitude, coordinate.latitude]
    }

    private static func bearing(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D
    ) -> CLLocationDirection {
        let startLatitude = start.latitude * .pi / 180
        let endLatitude = end.latitude * .pi / 180
        let deltaLongitude = (end.longitude - start.longitude) * .pi / 180
        let y = sin(deltaLongitude) * cos(endLatitude)
        let x = cos(startLatitude) * sin(endLatitude)
            - sin(startLatitude) * cos(endLatitude) * cos(deltaLongitude)
        let degrees = atan2(y, x) * 180 / .pi
        return (degrees + 360).truncatingRemainder(dividingBy: 360)
    }
}
