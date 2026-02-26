import CoreLocation

public struct NavigationRouteTrackingRenderState {
    public let markerCoordinate: CLLocationCoordinate2D
    public let markerHeading: CLLocationDirection
    public let markerTransitionDuration: TimeInterval
    public let remainingPath: [CLLocationCoordinate2D]
    public let connectorCoordinates: [CLLocationCoordinate2D]?
    public let hasArrived: Bool

    public init(
        markerCoordinate: CLLocationCoordinate2D,
        markerHeading: CLLocationDirection,
        markerTransitionDuration: TimeInterval,
        remainingPath: [CLLocationCoordinate2D],
        connectorCoordinates: [CLLocationCoordinate2D]?,
        hasArrived: Bool
    ) {
        self.markerCoordinate = markerCoordinate
        self.markerHeading = markerHeading
        self.markerTransitionDuration = markerTransitionDuration
        self.remainingPath = remainingPath
        self.connectorCoordinates = connectorCoordinates
        self.hasArrived = hasArrived
    }
}
