# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**IMap (MapPack)** is a Swift Package Manager library providing a unified map interface that abstracts over multiple map providers (Google Maps and MapLibre). The library allows iOS apps to switch between map providers without changing application code.

**Platform**: iOS 16.6+
**Language**: Swift 5.9+
**Dependencies**: 
- Google Maps SDK (9.4.0+)
- MapLibre Navigation iOS (main branch)

## Build Commands

### Build the package
```bash
swift build
```

### Build with specific configuration
```bash
swift build -c release
swift build -c debug
```

### Run tests
```bash
swift test
```

### Clean build artifacts
```bash
swift package clean
```

### Open in Xcode
```bash
xed .
```

## Architecture

### Core Abstraction Pattern

The library uses the **Strategy Pattern** with factory instantiation to provide a unified interface across map providers:

1. **MapProviderProtocol** (`Sources/MapPack/MapProviders/MapProviderProtocol.swift`) - Core protocol defining the common interface all map providers must implement
2. **MapProviderFactory** (`Sources/MapPack/MapProviders/MapProviderFactory.swift`) - Factory for creating provider instances (`.google` or `.mapLibre`)
3. **UniversalMapView** (`Sources/MapPack/Map/UniversalMapView.swift`) - SwiftUI view component that displays the selected map provider
4. **UniversalMapViewModel** (`Sources/MapPack/Map/UniversalMapViewModel.swift`) - ObservableObject managing map state and coordinating provider operations

### Provider Implementations

Each map provider has its own namespace under `Sources/MapPack/MapProviders/`:

- **Google**: `GoogleMapsProvider` wraps Google Maps SDK with UIKit-based `GoogleMapViewController`
- **Libre**: `MapLibreProvider` wraps MapLibre SDK with SwiftUI-friendly wrappers

### Key Components

**Models** (`Sources/MapPack/Models/`):
- **UniversalMapCamera** - Camera position abstraction
- **UniversalMapEdgeInsets** - Map padding abstraction
- **UniversalMapPolyline** - Route/path abstraction
- **UniversalMapStyles** - Style system (light/dark)
- **MapInteractionDelegate** - User interaction callbacks

**Marker System** (`Sources/MapPack/Map/UniversalMarker.swift`):
- `UniversalMapMarkerProtocol` defines marker interface
- `UniversalMarker` is the concrete implementation
- Markers are managed via string IDs for provider-independent reference

**Location Tracking** (`Sources/MapPack/Tracker/`):
- `LocationTrackingProtocol` - Tracking mode abstraction
- `LocationTrackingManager` - Manages camera tracking of user location or specific markers
- `MapTrackingMode` enum defines tracking states: `.none`, `.currentLocation(zoom:)`, `.marker(id:zoom:)`

### Configuration Pattern

Map providers are configured through dedicated config objects:
- **MapLibreConfig** - Configures style URLs for dark/lite themes (default uses Tilekiln Shortbread demo)
- **GoogleMapConfig** / **IMapConfig** - Google Maps specific configuration

### Delegation & Callbacks

The library uses two delegation patterns:
1. **MapInteractionDelegate** - Handles map gestures (tap, drag, marker selection)
2. **UniversalMapViewModelDelegate** - Notifies of map lifecycle events

Both use protocol-oriented design with default implementations for optional callbacks.

## Common Development Patterns

### Adding Map Provider Support

To add a new map provider:
1. Create provider class conforming to `MapProviderProtocol`
2. Add case to `MapProvider` enum in `MapProviderFactory.swift`
3. Implement factory method in `MapProviderFactory.createMapProvider()`
4. Create provider-specific wrapper models as needed

### Working with Markers

Markers are identified by string IDs and accessed through:
```swift
mapProviderInstance.addMarker(_ marker: UniversalMapMarkerProtocol)
mapProviderInstance.updateMarker(_ marker: UniversalMapMarkerProtocol)
mapProviderInstance.removeMarker(withId id: String)
mapProviderInstance.marker(byId id: String)
```

### Working with Polylines

Polylines follow similar pattern to markers:
```swift
mapProviderInstance.addPolyline(_ polyline: UniversalMapPolyline)
mapProviderInstance.removePolyline(withId id: String)
mapProviderInstance.focusOnPolyline(id: String, padding: UIEdgeInsets, animated: Bool)
```

### Camera Management

Camera updates can be animated or instant:
```swift
let camera = UniversalMapCamera(center: coordinate, zoom: 15, animate: true)
mapProviderInstance.updateCamera(to: camera)
```

Focus helpers for different scenarios:
- `focusMap(on:zoom:animated:)` - Focus on single coordinate
- `focusOn(coordinates:padding:animated:)` - Fit multiple coordinates
- `focusOnPolyline(id:padding:animated:)` - Fit polyline bounds

## Important Implementation Notes

### Provider-Specific Behavior

The codebase handles provider differences internally:
- Google Maps requires ignoring safe area differently than MapLibre (see `UniversalMapView.body`)
- Marker rendering differs: Google uses custom `PinView` UIKit overlays, MapLibre uses native annotations
- Style URLs must be configured via `MapLibreConfig.shared` before using MapLibre provider

### SwiftUI Integration

The library exposes a SwiftUI-first API but internally uses UIKit wrappers:
- Google: `UIViewControllerRepresentable` wrapping `GoogleMapViewController`
- MapLibre: Similar pattern with `MLNMapView`

### Thread Safety

Most map operations must occur on main thread. The protocol includes `@MainActor` annotations on relevant methods like `set(disabled:)` and `zoomOut(minLevel:shift:)`.

### Location Tracking

Location tracking is handled through `UniversalMapViewModel+LocationTracking.swift` extension:
- Implements `LocationTrackingProtocol`
- Automatically updates camera when tracking mode is active
- Supports tracking user location or specific marker IDs

## File Organization

```
Sources/
├── IMap/                          # Legacy target (unused)
└── MapPack/                       # Main library target
    ├── Map/                       # Core SwiftUI view & view model
    ├── MapProviders/              # Provider implementations
    │   ├── Google/                # Google Maps provider
    │   ├── Libre/                 # MapLibre provider
    │   ├── MapProviderProtocol.swift
    │   └── MapProviderFactory.swift
    ├── Models/                    # Shared data models
    ├── Tracker/                   # Location tracking system
    ├── Utils/                     # Utility extensions
    └── Assets.xcassets/          # Color assets
```

The library product name is **MapPack** (not IMap).
