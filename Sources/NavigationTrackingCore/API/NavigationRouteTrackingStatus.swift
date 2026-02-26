import CoreLocation

public enum NavigationRouteTrackingStatus {
    case onTrack(snappedLocation: CLLocationCoordinate2D, remainingPath: [CLLocationCoordinate2D])
    case outOfRoute
}
