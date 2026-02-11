# IMap Documentation

**IMap** (via `MapPack` library) is a universal map abstraction framework for iOS that provides a unified interface for working with both Google Maps and MapLibre (OpenStreetMap-based) mapping solutions. This package allows you to easily switch between map providers while maintaining the same API throughout your application.

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Requirements](#requirements)
4. [Installation](#installation)
5. [Quick Start](#quick-start)
6. [Documentation Index](#documentation-index)
7. [License](#license)

## Overview

IMap abstracts the differences between Google Maps SDK and MapLibre, providing a clean, protocol-oriented API that works seamlessly with SwiftUI. The framework follows modern Swift best practices, including:

- **Protocol-oriented design** for flexibility and testability
- **SwiftUI-first** approach with full support for declarative UI
- **Swift Concurrency** support with async/await and actors
- **Type safety** with strong typing throughout the API
- **Memory efficient** marker rendering with visibility culling

## Features

### Core Capabilities

- ✅ **Dual Provider Support**: Seamlessly switch between Google Maps and MapLibre
- ✅ **Unified API**: Single interface for all map operations
- ✅ **Markers**: Add, update, and remove custom markers with views
- ✅ **Polylines**: Draw and animate routes with customizable styling
- ✅ **Camera Control**: Programmatic camera positioning and animations
- ✅ **User Location**: Built-in user location tracking with custom icons
- ✅ **Interaction Delegates**: Respond to map events (taps, drags, marker selection)
- ✅ **Custom Styling**: Light/dark mode support with custom map styles
- ✅ **Route Tracking**: Track movement along predefined routes
- ✅ **Performance Optimized**: Smart marker visibility culling for better performance

### Advanced Features

- Custom user location markers with accuracy circles
- Animated polyline drawing
- Focus management for coordinates and polylines
- Configurable edge insets with animations
- Building visibility control
- Zoom level restrictions
- Map refresh rate control
- Address picker integration support

## Requirements

- **iOS**: 16.6+
- **Swift**: 5.9+
- **Xcode**: 15.0+

## Installation

### Swift Package Manager

Add IMap to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/IMap.git", from: "1.0.0")
]
```

Then add `MapPack` to your target dependencies:

```swift
targets: [
    .target(
        name: "YourApp",
        dependencies: ["MapPack"]
    )
]
```

### Manual Package.swift

The package automatically includes the required dependencies:
- **Google Maps SDK** (10.7.0+)
- **MapLibre Navigation** (from main branch)

## Quick Start

**For a complete getting started guide, see [Quick Start Guide](docs/QuickStart.md)**

### 1. Basic Setup

```swift
import SwiftUI
import MapPack

struct MapView: View {
    @StateObject private var viewModel: UniversalMapViewModel
    
    init() {
        // Create configuration
        let config = MapConfig(
            config: YourMapConfig(
                lightStyle: "your-light-style-url",
                darkStyle: "your-dark-style-url"
            )
        )
        
        // Initialize view model with Google Maps
        _viewModel = StateObject(
            wrappedValue: UniversalMapViewModel(
                mapProvider: .google,
                config: config
            )
        )
    }
    
    var body: some View {
        viewModel.makeMapView()
            .ignoresSafeArea()
    }
}
```

### 2. Adding Markers

```swift
// Create a custom marker view
let markerView = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
markerView.tintColor = .red
markerView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)

// Create and add marker
let marker = UniversalMarker(
    id: "location-1",
    coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    view: markerView
)

viewModel.addMarker(marker)
```

### 3. Drawing Routes

```swift
let coordinates = [
    CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4294),
    CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.4394)
]

let polyline = UniversalMapPolyline(
    coordinates: coordinates,
    color: .blue,
    width: 5.0
)

viewModel.addPolyline(polyline, animated: true)
```

### 4. Camera Control

```swift
// Focus on a location
viewModel.focusMap(
    on: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    zoom: 15,
    animated: true
)

// Fit to show all coordinates
viewModel.focusTo(coordinates: coordinates, padding: 50, animated: true)
```

## Documentation Index

Explore detailed documentation for each component:

### Core Components

- **[UniversalMapViewModel](docs/UniversalMapViewModel.md)** - Main view model for map control
- **[MapProviderProtocol](docs/MapProviderProtocol.md)** - Protocol defining map provider interface
- **[MapProvider](docs/MapProvider.md)** - Enumeration of available providers

### Providers

- **[GoogleMapsProvider](docs/GoogleMapsProvider.md)** - Google Maps implementation
- **[MapLibreProvider](docs/MapLibreProvider.md)** - MapLibre implementation
- **[MapProviderFactory](docs/MapProviderFactory.md)** - Factory for creating providers

### Models

- **[UniversalMapCamera](docs/UniversalMapCamera.md)** - Camera position and configuration
- **[UniversalMapPolyline](docs/UniversalMapPolyline.md)** - Polyline/route representation
- **[UniversalMapMarker](docs/UniversalMapMarker.md)** - Marker representation
- **[UniversalMapEdgeInsets](docs/UniversalMapEdgeInsets.md)** - Edge insets configuration
- **[UniversalMapStyles](docs/UniversalMapStyles.md)** - Map styling options

### Protocols

- **[UniversalMapMarkerProtocol](docs/UniversalMapMarkerProtocol.md)** - Protocol for markers
- **[MapConfigProtocol](docs/MapConfigProtocol.md)** - Configuration protocol
- **[MapInteractionDelegate](docs/MapInteractionDelegate.md)** - Interaction event handling
- **[UniversalMapStyleProtocol](docs/UniversalMapStyleProtocol.md)** - Map style protocol

### Advanced Features

- **[RouteTrackingManager](docs/docsRouteTrackingManager.md)** - Track movement along routes
- **[Marker Visibility Management](docs/MarkerVisibilityManagement.md)** - Performance optimization
- **[Custom User Location](docs/CustomUserLocation.md)** - Custom location markers

### Guides

- **[Quick Start Guide](docs/QuickStart.md)** - Get started in 5 minutes
- **[Migration Guide](docs/MigrationGuide.md)** - Switching between providers
- **[Styling Guide](docs/StylingGuide.md)** - Customizing map appearance
- **[Performance Guide](docs/PerformanceGuide.md)** - Optimizing map performance
- **[Integration Guide](docs/IntegrationGuide.md)** - Integrating with your app

## Architecture

IMap follows a protocol-oriented architecture:

```
┌─────────────────────────────────┐
│   UniversalMapViewModel         │  ← Your app interacts here
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│   MapProviderProtocol           │  ← Unified interface
└────────────┬────────────────────┘
             │
      ┌──────┴──────┐
      ▼             ▼
┌──────────┐  ┌──────────┐
│  Google  │  │ MapLibre │         ← Concrete implementations
│  Maps    │  │          │
└──────────┘  └──────────┘
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues, questions, or contributions, please use the GitHub issue tracker.

## License

[Your License Here]

---

**Note**: Google Maps requires an API key. Make sure to configure it properly before using the Google Maps provider.
