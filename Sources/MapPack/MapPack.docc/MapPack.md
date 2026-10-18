# ``MapPack``

Universal map abstraction for iOS with optional reusable navigation tracking primitives.

## Overview

`MapPack` provides:
- a unified map API across Google Maps and MapLibre,
- marker/polyline/camera primitives via `UniversalMapViewModel`,
- **SwiftUI and UIKit entry points** over the same view model — `UniversalMapView` for
  SwiftUI, `UniversalMapViewController` / `UniversalMapContainerView` for UIKit,
- re-exported `NavigationTrackingCore` symbols for route tracking logic.

Use `MapPack` when you need both rendering and tracking.  
Use `NavigationTrackingCore` directly if you only need tracking logic.

## Swift Compatibility and Concurrency

The package supports Swift 6 and Swift 5 language modes. A consuming app may
remain in Swift 5 language mode while `MapPack` builds in Swift 6 mode, provided
both targets are built by a toolchain that understands the package source.

Map providers, provider registries, map view models, markers, and device-heading
providers are main-actor isolated because they own UIKit or map-SDK state.
Create and mutate these types from `@MainActor` code. Non-UI navigation tracking
continues to use structured concurrency independently of the main actor.

## Current-Location Appearance

MapLibre can switch its current-location indicator between the SDK default, an
image, and the bundled live 3D car arrow:

```swift
try await mapViewModel.set(
    userLocationAppearance: .model3D(.carArrow)
)

// Restore MapLibre's regular current-location indicator.
try await mapViewModel.set(userLocationAppearance: .standard)
```

The 3D model follows the same heading rules as the existing current-location
image and changes perspective with MapLibre's live camera pitch. A soft grounding
shadow is composited over the map. The model is loaded asynchronously, cached,
and reused between location updates.

Google Maps continues to support `.standard` and `.image`. Requesting `.model3D`
throws ``UserLocationAppearanceError/unsupportedThreeDimensionalModel(providerName:)``
without terminating the app.

If MapLibre cannot load the requested current-location model, it restores
``UserLocationAppearance/standard`` and rethrows the loading error so the app can
record or present the failure.

## Reusable 3D Markers

MapLibre also supports coordinate-driven 3D markers independently of the SDK's
current-location annotation:

```swift
var vehicle = UniversalMap3DMarker(
    id: "navigation-vehicle",
    coordinate: initialCoordinate,
    heading: initialHeading,
    scale: 0.9,
    model: .carArrow
)

try await mapViewModel.addMarker(vehicle)

vehicle.coordinate = nextCoordinate
vehicle.heading = nextHeading
vehicle.scale = 1.0
try await mapViewModel.updateMarker(vehicle)

mapViewModel.removeMarker(withId: vehicle.id)
```

Updates with the same ID and model mutate the existing annotation and 3D render
view. The marker is recomposed for live map bearing and pitch changes. A different
model configuration intentionally replaces that marker after loading the new model.
Google Maps continues to report an unsupported-3D error for this API.

## MapLibre Pitch Gestures

MapLibre keeps pitch gestures disabled by default for compatibility. Enable them
through ``MapLibreConfig`` when the user should be able to tilt the map:

```swift
let config = MapLibreConfig(isPitchEnabled: true)
let mapConfig = MapConfig(config: config)
```

Changing the configuration with `UniversalMapViewModel.set(config:)` also updates
an existing MapLibre view. The flag controls user gestures only; camera APIs can
still apply a pitch while it is disabled.

## Route Polylines

Use a cased route polyline when route geometry should remain readable over roads,
labels, and differently colored map styles:

```swift
let routeLine = UniversalMapPolyline.route(
    id: "active-route",
    coordinates: orderedRouteCoordinates
)
mapViewModel.addPolyline(routeLine)
```

The main route stroke and its darker casing share one geometry and remain synchronized
when the polyline is animated or updated. Both MapLibre and Google Maps render the
two-stroke presentation. Regular ``UniversalMapPolyline`` instances remain single-line
unless a ``UniversalMapPolylineCasing`` is supplied.

## Topics

### Map Rendering

- ``UniversalMapViewModel``
- ``MapLibreConfig``
- ``MapLibreConfigProtocol``
- ``UniversalMapPolyline``
- ``UniversalMapPolylineCasing``
- ``UniversalMapCamera``
- ``UniversalMarker``
- ``UniversalMap3DMarker``
- ``UserLocationAppearance``
- ``UserLocation3DModel``
- ``UserLocationAppearanceError``

### UIKit Integration

- ``UniversalMapViewController``
- ``UniversalMapContainerView``
- ``UniversalMapConfiguring``

### Navigation Tracking Core

- ``NavigationRouteTrackingSessionManager``
- ``NavigationRouteTrackingConfig``
- ``NavigationRouteTrackingUpdate``
- ``NavigationRouteProgressGeometry``
- ``NavigationRouteProgressAnimationService``
- ``NavigationHeadingComputationService``

### Turn-by-Turn Navigation

MapLibre can present a dedicated, full-screen turn-by-turn controller without changing
the existing universal map instance:

```swift
let route = try MapNavigationRoute(
    coordinates: orderedRouteCoordinates,
    distance: routeDistance,
    expectedTravelTime: routeDuration
)
let configuration = MapNavigationConfiguration(
    dayStyleURL: lightStyleURL,
    nightStyleURL: darkStyleURL
)
let controller = MapNavigationViewControllerFactory.makeViewController(
    for: .mapLibre,
    route: route,
    configuration: configuration
)
```

``MapNavigationViewControllerFactory`` returns `nil` for Google Maps. A geometry-only
``MapNavigationRoute`` provides route snapping, progress, ETA, arrival handling, and
the navigation camera. Detailed maneuver and voice instructions require a
Directions-compatible route response.
