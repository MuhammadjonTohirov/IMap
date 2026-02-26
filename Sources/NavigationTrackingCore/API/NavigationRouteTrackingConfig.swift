import CoreLocation

public struct NavigationRouteTrackingConfig {
    public let routeSnapThreshold: CLLocationDistance
    public let routeArrivalThreshold: CLLocationDistance
    public let connectorHideThreshold: CLLocationDistance

    public let headingSmoothingFactor: Double
    public let routeHeadingLookAheadDistance: CLLocationDistance
    public let minReliableCourseSpeed: CLLocationSpeed
    public let maxHeadingTurnRatePerSecond: CLLocationDirection
    public let serverHeadingMaxAge: TimeInterval

    public let markerAnimationFallbackDuration: TimeInterval
    public let markerAnimationMinDuration: TimeInterval
    public let markerAnimationMaxDuration: TimeInterval

    public init(
        routeSnapThreshold: CLLocationDistance,
        routeArrivalThreshold: CLLocationDistance,
        connectorHideThreshold: CLLocationDistance,
        headingSmoothingFactor: Double,
        routeHeadingLookAheadDistance: CLLocationDistance,
        minReliableCourseSpeed: CLLocationSpeed,
        maxHeadingTurnRatePerSecond: CLLocationDirection,
        serverHeadingMaxAge: TimeInterval,
        markerAnimationFallbackDuration: TimeInterval,
        markerAnimationMinDuration: TimeInterval,
        markerAnimationMaxDuration: TimeInterval
    ) {
        self.routeSnapThreshold = routeSnapThreshold
        self.routeArrivalThreshold = routeArrivalThreshold
        self.connectorHideThreshold = connectorHideThreshold
        self.headingSmoothingFactor = headingSmoothingFactor
        self.routeHeadingLookAheadDistance = routeHeadingLookAheadDistance
        self.minReliableCourseSpeed = minReliableCourseSpeed
        self.maxHeadingTurnRatePerSecond = maxHeadingTurnRatePerSecond
        self.serverHeadingMaxAge = serverHeadingMaxAge
        self.markerAnimationFallbackDuration = markerAnimationFallbackDuration
        self.markerAnimationMinDuration = markerAnimationMinDuration
        self.markerAnimationMaxDuration = markerAnimationMaxDuration
    }
}
