import CoreLocation

public struct NavigationHeadingComputationInput {
    public let snappedCoordinate: CLLocationCoordinate2D
    public let remainingPath: [CLLocationCoordinate2D]
    public let location: CLLocation
    public let lastDisplayCoordinate: CLLocationCoordinate2D?
    public let currentDisplayHeading: CLLocationDirection
    public let routeHeadingStrategy: NavigationRouteHeadingStrategy
    public let lookAheadDistance: CLLocationDistance
    public let minReliableCourseSpeed: CLLocationSpeed
    public let serverHeading: NavigationServerHeading?
    public let serverHeadingMaxAge: TimeInterval

    public init(
        snappedCoordinate: CLLocationCoordinate2D,
        remainingPath: [CLLocationCoordinate2D],
        location: CLLocation,
        lastDisplayCoordinate: CLLocationCoordinate2D?,
        currentDisplayHeading: CLLocationDirection,
        routeHeadingStrategy: NavigationRouteHeadingStrategy,
        lookAheadDistance: CLLocationDistance,
        minReliableCourseSpeed: CLLocationSpeed,
        serverHeading: NavigationServerHeading?,
        serverHeadingMaxAge: TimeInterval
    ) {
        self.snappedCoordinate = snappedCoordinate
        self.remainingPath = remainingPath
        self.location = location
        self.lastDisplayCoordinate = lastDisplayCoordinate
        self.currentDisplayHeading = currentDisplayHeading
        self.routeHeadingStrategy = routeHeadingStrategy
        self.lookAheadDistance = lookAheadDistance
        self.minReliableCourseSpeed = minReliableCourseSpeed
        self.serverHeading = serverHeading
        self.serverHeadingMaxAge = serverHeadingMaxAge
    }
}
