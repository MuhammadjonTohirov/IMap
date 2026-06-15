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
