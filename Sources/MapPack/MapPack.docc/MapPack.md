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

## Topics

### Map Rendering

- ``UniversalMapViewModel``
- ``UniversalMapPolyline``
- ``UniversalMapCamera``
- ``UniversalMarker``

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
