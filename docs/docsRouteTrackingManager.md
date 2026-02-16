# NavigationRouteTrackingManager

`NavigationRouteTrackingManager` is the low-level route snapping component in `NavigationTrackingCore`.

Use this type when you only need nearest-point snapping and remaining-path extraction.
For full navigation behavior (heading smoothing, animation duration, arrival checks), prefer `NavigationRouteTrackingSessionManager`.

## Declaration

```swift
public final class NavigationRouteTrackingManager
```

## Initialization

```swift
public init(routeCoordinates: [CLLocationCoordinate2D], threshold: CLLocationDistance = 30)
```

Parameters:
- `routeCoordinates`: full route path.
- `threshold`: max distance from route to still be considered on-route.

Example:

```swift
let tracker = NavigationRouteTrackingManager(
    routeCoordinates: route,
    threshold: 50
)
```

## Status

```swift
public enum NavigationRouteTrackingStatus {
    case onTrack(snappedLocation: CLLocationCoordinate2D, remainingPath: [CLLocationCoordinate2D])
    case outOfRoute
}
```

- `onTrack`: returns snapped coordinate and remaining path from snapped point.
- `outOfRoute`: current location is beyond threshold.

## Update API

```swift
public func updateDriverLocation(_ location: CLLocationCoordinate2D) -> NavigationRouteTrackingStatus
```

Example:

```swift
switch tracker.updateDriverLocation(driverCoordinate) {
case .onTrack(let snapped, let remainingPath):
    updateDriverMarker(snapped)
    updateRemainingPolyline(remainingPath)

case .outOfRoute:
    requestReroute()
}
```

## Algorithm Summary

1. Iterate every route segment.
2. Project location onto each segment.
3. Select nearest projected point.
4. Compare nearest distance with `threshold`.
5. Build `remainingPath` from snapped point to route end.

## Recommended Usage

Use `NavigationRouteTrackingManager` directly when:
- you only need snap-to-route and remaining path,
- you already own heading, animation, and reroute state elsewhere.

Use `NavigationRouteTrackingSessionManager` when:
- you want production navigation behavior out of the box,
- you need smoothed heading and transition durations,
- you want arrival and connector handling in one place.

See detailed integration:
- `docs/docsNavigationTrackingCore.md`
