# Quick Start Guide

Get up and running with IMap in minutes!

## Installation

### Step 1: Add Package Dependency

Add IMap to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/IMap.git", from: "1.0.0")
]
```

Add to your target:

```swift
.target(
    name: "YourApp",
    dependencies: ["MapPack"]
)
```

### Step 2: Import the Framework

```swift
import MapPack
import SwiftUI
```

## Basic Setup

### 1. Create a Map Configuration

First, create a configuration that conforms to `MapConfigProtocol`:

```swift
import Foundation

struct MyMapConfig: UniversalMapConfigProtocol {
    var lightStyle: String = "your-light-style-url"
    var darkStyle: String = "your-dark-style-url"
}

// For Google Maps
struct GoogleMapConfig: GoogleMapsConfigProtocol {
    var accessKey: String = "YOUR_GOOGLE_MAPS_API_KEY"
    var lightStyle: String = GMapStyles.default
    var darkStyle: String = GMapStyles.night
}
```

### 2. Create the View Model

```swift
import SwiftUI
import MapPack

struct MapView: View {
    @StateObject private var viewModel: UniversalMapViewModel
    
    init(mapProvider: MapProvider = .google) {
        let config = MapConfig(
            config: GoogleMapConfig(accessKey: "YOUR_API_KEY")
        )
        
        _viewModel = StateObject(
            wrappedValue: UniversalMapViewModel(
                mapProvider: mapProvider,
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

### 3. Display the Map

```swift
struct ContentView: View {
    var body: some View {
        MapView()
    }
}
```

That's it! You now have a working map.

## Common Tasks

### Add a Marker

```swift
// Create a custom marker view
let markerView = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
markerView.tintColor = .red
markerView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)

// Create marker
let marker = UniversalMarker(
    id: "marker-1",
    coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    view: markerView
)

// Add to map
viewModel.addMarker(marker)
```

### Draw a Route

```swift
let coordinates = [
    CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4294),
    CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.4394)
]

let polyline = UniversalMapPolyline(
    coordinates: coordinates,
    color: .systemBlue,
    width: 5.0
)

viewModel.addPolyline(polyline, animated: true)
```

### Move the Camera

```swift
Task {
    await viewModel.focusMap(
        on: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        zoom: 15,
        animated: true
    )
}
```

### Show User Location

```swift
viewModel.showUserLocation(true)
```

## Full Example

Here's a complete example with markers, routes, and camera control:

```swift
import SwiftUI
import MapPack
import CoreLocation

struct CompleteMapExample: View {
    @StateObject private var viewModel: UniversalMapViewModel
    
    init() {
        let config = MapConfig(
            config: GoogleMapConfig(accessKey: "YOUR_API_KEY")
        )
        
        _viewModel = StateObject(
            wrappedValue: UniversalMapViewModel(
                mapProvider: .google,
                config: config
            )
        )
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Map
            viewModel.makeMapView()
                .ignoresSafeArea()
            
            // Controls
            VStack(spacing: 16) {
                Button("Add Marker") {
                    addMarker()
                }
                
                Button("Draw Route") {
                    drawRoute()
                }
                
                Button("My Location") {
                    focusOnUser()
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .padding()
        }
        .onAppear {
            setupMap()
        }
    }
    
    private func setupMap() {
        viewModel.showUserLocation(true)
    }
    
    private func addMarker() {
        let markerView = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
        markerView.tintColor = .red
        markerView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        
        let marker = UniversalMarker(
            id: UUID().uuidString,
            coordinate: CLLocationCoordinate2D(
                latitude: 37.7749 + Double.random(in: -0.01...0.01),
                longitude: -122.4194 + Double.random(in: -0.01...0.01)
            ),
            view: markerView
        )
        
        viewModel.addMarker(marker)
    }
    
    private func drawRoute() {
        let coordinates = [
            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4294),
            CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.4394)
        ]
        
        let polyline = UniversalMapPolyline(
            coordinates: coordinates,
            color: .systemBlue,
            width: 5.0
        )
        
        viewModel.addPolyline(polyline, animated: true)
        
        // Focus on route
        Task {
            await viewModel.focusOnPolyline(id: polyline.id, animated: true)
        }
    }
    
    private func focusOnUser() {
        Task {
            await viewModel.focusToCurrentLocation(animated: true)
        }
    }
}
```

## Next Steps

Now that you have the basics, explore more advanced features:

- **[Marker Management](UniversalMapMarker.md)** - Custom markers and interactions
- **[Route Tracking](RouteTrackingManager.md)** - Track movement along routes
- **[Styling](StylingGuide.md)** - Customize map appearance
- **[Interaction Handling](MapInteractionDelegate.md)** - Respond to user actions
- **[Camera Control](UniversalMapCamera.md)** - Advanced camera animations

## Troubleshooting

### Map Not Showing

1. Check your API key configuration
2. Ensure you've added location permissions to Info.plist
3. Verify network connectivity

### Markers Not Appearing

1. Check coordinate values are valid
2. Ensure marker views have non-zero frames
3. Verify marker is within visible region

### Build Errors

1. Clean build folder (Cmd+Shift+K)
2. Reset package caches
3. Check minimum iOS version (16.6+)

## Getting Help

- Check the [FAQ](FAQ.md)
- Review [API Documentation](../README.md)
- Open an issue on GitHub

---

Ready to build amazing map experiences! 🗺️
