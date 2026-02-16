import CoreLocation

public protocol NavigationHeadingComputing {
    func computeTargetHeading(input: NavigationHeadingComputationInput) -> CLLocationDirection
    func smoothHeading(
        from current: CLLocationDirection,
        to target: CLLocationDirection,
        factor: Double,
        deltaTime: TimeInterval,
        maxTurnRatePerSecond: CLLocationDirection
    ) -> CLLocationDirection
    func bearing(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> CLLocationDirection
    func distance(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> CLLocationDistance
}
