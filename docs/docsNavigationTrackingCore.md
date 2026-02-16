# NavigationTrackingCore

`NavigationTrackingCore` is the reusable navigation engine extracted from the test app.

It is responsible for:
- snapping raw GPS to the route,
- computing stable heading,
- producing render states for marker and remaining polyline,
- exposing explicit `onTrack` and `outOfRoute` states,
- driving smooth progress animation over route distance.

It does not render the map. Rendering stays in your app or in a map adapter.

## Import Options

If your target depends on `MapPack`, tracking symbols are re-exported:

```swift
import MapPack
```

If you want tracking logic without `MapPack`, depend on `NavigationTrackingCore` and import directly:

```swift
import NavigationTrackingCore
```

## Core Types

- `NavigationRouteTrackingSessionManager`: high-level session state machine for route tracking.
- `NavigationRouteTrackingConfig`: tuning values (snap threshold, heading smoothing, animation bounds).
- `NavigationHeadingComputationService`: heading strategy implementation.
- `NavigationRouteProgressGeometry`: route-distance geometry and interpolation utilities.
- `NavigationRouteProgressAnimationService`: display-link based progress animator.
- `NavigationRouteTrackingUpdate`: update result (`.onTrack` / `.outOfRoute`).

## Recommended Integration Flow

### 1. Build Tracking Config

```swift
let trackingConfig = NavigationRouteTrackingConfig(
    routeSnapThreshold: 80,
    routeArrivalThreshold: 8,
    connectorHideThreshold: 1.2,
    headingSmoothingFactor: 0.28,
    routeHeadingLookAheadDistance: 12,
    minReliableCourseSpeed: 2.5,
    maxHeadingTurnRatePerSecond: 120,
    serverHeadingMaxAge: 3.0,
    markerAnimationFallbackDuration: 0.35,
    markerAnimationMinDuration: 0.15,
    markerAnimationMaxDuration: 1.0
)
```

### 2. Create Session + Services

```swift
let headingService = NavigationHeadingComputationService()
let trackingSession = NavigationRouteTrackingSessionManager(
    config: trackingConfig,
    headingService: headingService
)
let progressAnimator = NavigationRouteProgressAnimationService()

var routeGeometry: NavigationRouteProgressGeometry?
var currentRouteProgress: CLLocationDistance = 0
```

### 3. Configure Route

```swift
guard let setup = trackingSession.configureRoute(
    coordinates: routeCoordinates,
    currentLocation: latestLocation?.coordinate
) else {
    return
}

routeGeometry = NavigationRouteProgressGeometry(route: setup.routeCoordinates)
currentRouteProgress = routeGeometry?.progress(of: setup.initialMarkerCoordinate) ?? 0

// Render initial state
renderMarker(at: setup.initialMarkerCoordinate, heading: setup.initialHeading)
renderRemainingRoute(setup.routeCoordinates)
```

### 4. Process Location Updates

```swift
func handleLocation(_ location: CLLocation) {
    guard let update = trackingSession.handleLocationUpdate(location) else { return }

    switch update {
    case .onTrack(let renderState):
        handleOnTrack(renderState)

    case .outOfRoute:
        handleOutOfRoute(location)
    }
}
```

### 5. Render `.onTrack` with Smooth Marker + Polyline

```swift
func handleOnTrack(_ renderState: NavigationRouteTrackingRenderState) {
    guard let routeGeometry else {
        renderMarker(at: renderState.markerCoordinate, heading: renderState.markerHeading)
        renderRemainingRoute(renderState.remainingPath)
        renderConnector(renderState.connectorCoordinates)
        return
    }

    let rawTargetProgress = routeGeometry.progress(fromRemainingPath: renderState.remainingPath)
        ?? routeGeometry.progress(of: renderState.markerCoordinate)

    // Prevent visual backward jumps from noisy GPS updates.
    let targetProgress = max(currentRouteProgress, rawTargetProgress)

    progressAnimator.animate(
        from: currentRouteProgress,
        to: routeGeometry.clamp(progress: targetProgress),
        duration: renderState.markerTransitionDuration,
        onUpdate: { progress in
            let clamped = routeGeometry.clamp(progress: progress)
            currentRouteProgress = clamped

            let markerCoordinate = routeGeometry.coordinate(at: clamped)
            let markerHeading = routeGeometry.heading(at: clamped, fallback: renderState.markerHeading)
            renderMarker(at: markerCoordinate, heading: markerHeading)

            let remaining = routeGeometry.remainingRoute(from: clamped)
            renderRemainingRoute(remaining)
        },
        onCompletion: nil
    )

    renderConnector(renderState.connectorCoordinates)

    if renderState.hasArrived {
        stopTracking()
    }
}
```

### 6. Handle Off-Route + Reroute

```swift
func handleOutOfRoute(_ location: CLLocation) {
    renderMarker(
        at: location.coordinate,
        heading: location.course >= 0 ? location.course : trackingSession.displayHeading
    )

    requestReroute(from: location.coordinate, to: trackingSession.routeCoordinates.last)
}

func applyReroute(_ newRoute: [CLLocationCoordinate2D], currentLocation: CLLocationCoordinate2D) {
    guard let setup = trackingSession.configureRoute(
        coordinates: newRoute,
        currentLocation: currentLocation
    ) else { return }

    progressAnimator.cancel()
    routeGeometry = NavigationRouteProgressGeometry(route: setup.routeCoordinates)
    currentRouteProgress = routeGeometry?.progress(of: currentLocation) ?? 0

    renderRemainingRoute(setup.routeCoordinates)
    renderMarker(at: setup.initialMarkerCoordinate, heading: setup.initialHeading)
}
```

## Heading Input from Server

If your backend provides heading, feed it into the session:

```swift
trackingSession.updateServerHeading(serverHeading, timestamp: serverTimestamp)
```

You can switch heading strategy at runtime:

```swift
trackingSession.setRouteHeadingStrategy(.lookAhead)
// or
trackingSession.setRouteHeadingStrategy(.threePointWeighted)
```

`NavigationHeadingComputationService` uses the freshest heading source in this order:
1. Fresh server heading.
2. Route-derived heading.
3. Movement-derived heading.
4. Device course (if speed is reliable).
5. Current display heading fallback.

## Camera Follow is Optional

Tracking and camera follow should be decoupled. Keep a separate toggle in presentation:

```swift
if isCameraFollowEnabled {
    mapViewModel.trackMarker(markerId, zoom: 18)
} else {
    mapViewModel.stopTracking()
}
```

This allows users to inspect the whole route while tracking still runs.

## Production Notes

- Keep all map mutations on main thread / `@MainActor`.
- Call `progressAnimator.cancel()` when tracking stops or route is replaced.
- Preserve monotonic progress (`max(current, next)`) to avoid marker/polyline snap-back.
- Debounce reroute requests when repeatedly off-route.
- Add regression tests around:
  - out-of-route detection,
  - route replacement,
  - no backward progress,
  - arrival threshold behavior.

## Minimal Rendering Contract

Your map adapter only needs these operations:
- `renderMarker(at:heading:)`
- `renderRemainingRoute(_:)`
- `renderConnector(_:)`
- `trackMarker(...)` / `stopTracking()`

This keeps `NavigationTrackingCore` reusable across MapLibre, Google Maps, or any future provider.
