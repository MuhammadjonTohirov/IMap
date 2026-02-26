import CoreLocation

public struct NavigationRouteSetupState {
    public let routeCoordinates: [CLLocationCoordinate2D]
    public let initialMarkerCoordinate: CLLocationCoordinate2D
    public let initialHeading: CLLocationDirection

    public init(
        routeCoordinates: [CLLocationCoordinate2D],
        initialMarkerCoordinate: CLLocationCoordinate2D,
        initialHeading: CLLocationDirection
    ) {
        self.routeCoordinates = routeCoordinates
        self.initialMarkerCoordinate = initialMarkerCoordinate
        self.initialHeading = initialHeading
    }
}
