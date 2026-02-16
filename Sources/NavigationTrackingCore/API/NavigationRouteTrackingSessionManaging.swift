import CoreLocation

public protocol NavigationRouteTrackingSessionManaging: AnyObject {
    var routeCoordinates: [CLLocationCoordinate2D] { get }
    var displayHeading: CLLocationDirection { get }
    var displayCoordinate: CLLocationCoordinate2D? { get }

    func configureRoute(
        coordinates: [CLLocationCoordinate2D],
        currentLocation: CLLocationCoordinate2D?
    ) -> NavigationRouteSetupState?

    func handleLocationUpdate(_ location: CLLocation) -> NavigationRouteTrackingUpdate?
    func resetTrackingState()
    func clearRouteState()
    func updateServerHeading(_ heading: CLLocationDirection, timestamp: Date)
    func setRouteHeadingStrategy(_ strategy: NavigationRouteHeadingStrategy)
}
