# UniversalMapCamera

`UniversalMapCamera` represents the camera position and configuration for the map view, providing a provider-agnostic way to control the map's viewpoint.

## Overview

The camera defines:
- **Where** the map is looking (center coordinate)
- **How close** the view is (zoom level)
- **Which direction** the map is facing (bearing)
- **At what angle** we're viewing (pitch/tilt)
- **How** to get there (animation)

## Structure Declaration

```swift
public struct UniversalMapCamera
```

## Properties

### center

```swift
public var center: CLLocationCoordinate2D
```

The geographic coordinate at the center of the map view.

**Type:** `CLLocationCoordinate2D` from CoreLocation

**Example:**
```swift
let center = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
```

### zoom

```swift
public var zoom: Double
```

The zoom level of the camera.

**Range:**
- Typically 0-22 (provider-dependent)
- `0`: Whole world
- `5`: Continent
- `10`: City
- `15`: Streets
- `20`: Buildings

**Default:** `15`

### bearing

```swift
public var bearing: Double
```

The heading/direction the camera is facing, measured in degrees clockwise from north.

**Range:** 0-360 degrees
- `0`: North
- `90`: East
- `180`: South
- `270`: West

**Default:** `0` (north)

**Use Case:** Useful for navigation where you want the map to rotate with the user's direction.

### pitch

```swift
public var pitch: Double
```

The viewing angle in degrees from the horizon.

**Range:** 0-90 degrees
- `0`: Looking straight down (2D map)
- `45`: Typical 3D view
- `60`: Steep 3D angle
- `90`: Horizontal view (not typically used)

**Default:** `0` (top-down view)

**Use Case:** Creates a 3D perspective view, useful for showing buildings and terrain.

### animate

```swift
public var animate: Bool
```

Whether camera transitions should be animated.

**Default:** `true`

**Values:**
- `true`: Smooth animated transition
- `false`: Instant jump to new position

## Initialization

```swift
public init(
    center: CLLocationCoordinate2D,
    zoom: Double = 15,
    bearing: Double = 0,
    pitch: Double = 0,
    animate: Bool = true
)
```

**Example:**

```swift
let camera = UniversalMapCamera(
    center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    zoom: 16,
    bearing: 90,
    pitch: 45,
    animate: true
)

viewModel.updateCamera(to: camera)
```

## Usage Examples

### Basic 2D Camera

```swift
let camera = UniversalMapCamera(
    center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    zoom: 15
)

viewModel.updateCamera(to: camera)
```

### 3D Perspective View

```swift
let camera = UniversalMapCamera(
    center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    zoom: 17,
    bearing: 0,
    pitch: 60, // Tilted view
    animate: true
)

viewModel.updateCamera(to: camera)
```

### Navigation View (Rotated with Direction)

```swift
func updateNavigationCamera(location: CLLocation, heading: CLLocationDirection) {
    let camera = UniversalMapCamera(
        center: location.coordinate,
        zoom: 18,
        bearing: heading, // Map rotates with user
        pitch: 45,
        animate: true
    )
    
    viewModel.updateCamera(to: camera)
}
```

### Instant Camera Jump (No Animation)

```swift
let camera = UniversalMapCamera(
    center: userLocation,
    zoom: 16,
    animate: false // Instant transition
)

viewModel.updateCamera(to: camera)
```

### Fly-Over Effect

```swift
func flyOver(locations: [CLLocationCoordinate2D]) async {
    for (index, location) in locations.enumerated() {
        let camera = UniversalMapCamera(
            center: location,
            zoom: 17,
            bearing: Double(index * 60), // Rotate as we fly
            pitch: 60,
            animate: true
        )
        
        viewModel.updateCamera(to: camera)
        
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
    }
}
```

### Zoom Levels Reference

```swift
enum MapZoomLevel {
    static let world: Double = 0
    static let continent: Double = 5
    static let country: Double = 8
    static let city: Double = 10
    static let district: Double = 13
    static let streets: Double = 15
    static let buildings: Double = 17
    static let detailed: Double = 20
}

let camera = UniversalMapCamera(
    center: coordinate,
    zoom: MapZoomLevel.buildings
)
```

### Camera Presets

```swift
extension UniversalMapCamera {
    static func overview(of coordinate: CLLocationCoordinate2D) -> UniversalMapCamera {
        UniversalMapCamera(
            center: coordinate,
            zoom: 12,
            bearing: 0,
            pitch: 0,
            animate: true
        )
    }
    
    static func streetLevel(at coordinate: CLLocationCoordinate2D, 
                           heading: CLLocationDirection = 0) -> UniversalMapCamera {
        UniversalMapCamera(
            center: coordinate,
            zoom: 18,
            bearing: heading,
            pitch: 45,
            animate: true
        )
    }
    
    static func navigation(at coordinate: CLLocationCoordinate2D,
                          heading: CLLocationDirection) -> UniversalMapCamera {
        UniversalMapCamera(
            center: coordinate,
            zoom: 17,
            bearing: heading,
            pitch: 60,
            animate: true
        )
    }
    
    static func overview3D(at coordinate: CLLocationCoordinate2D) -> UniversalMapCamera {
        UniversalMapCamera(
            center: coordinate,
            zoom: 15,
            bearing: 45,
            pitch: 55,
            animate: true
        )
    }
}

// Usage
viewModel.updateCamera(to: .navigation(at: userLocation, heading: 135))
```

## Advanced Examples

### Smooth Camera Interpolation

```swift
class CameraAnimator {
    private let viewModel: UniversalMapViewModel
    
    func smoothTransition(from: CLLocationCoordinate2D, 
                         to: CLLocationCoordinate2D,
                         duration: TimeInterval = 2.0) async {
        let steps = 20
        let stepDuration = duration / Double(steps)
        
        for i in 0...steps {
            let progress = Double(i) / Double(steps)
            
            let lat = from.latitude + (to.latitude - from.latitude) * progress
            let lon = from.longitude + (to.longitude - from.longitude) * progress
            
            let camera = UniversalMapCamera(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                zoom: 15,
                animate: false // Manual animation
            )
            
            viewModel.updateCamera(to: camera)
            
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
        }
    }
}
```

### Orbit Animation

```swift
func orbitLocation(_ coordinate: CLLocationCoordinate2D) async {
    for angle in stride(from: 0, to: 360, by: 10) {
        let camera = UniversalMapCamera(
            center: coordinate,
            zoom: 16,
            bearing: Double(angle),
            pitch: 50,
            animate: true
        )
        
        viewModel.updateCamera(to: camera)
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
    }
}
```

### Zoom Animation

```swift
func zoomToLocation(_ coordinate: CLLocationCoordinate2D) async {
    // Start far away
    let startCamera = UniversalMapCamera(
        center: coordinate,
        zoom: 5,
        animate: false
    )
    viewModel.updateCamera(to: startCamera)
    
    try? await Task.sleep(nanoseconds: 500_000_000)
    
    // Zoom in smoothly
    let endCamera = UniversalMapCamera(
        center: coordinate,
        zoom: 17,
        pitch: 45,
        animate: true
    )
    viewModel.updateCamera(to: endCamera)
}
```

### Follow Mode

```swift
class FollowModeManager {
    private let viewModel: UniversalMapViewModel
    private var isFollowing = true
    
    func updateLocation(_ location: CLLocation, heading: CLLocationDirection) {
        guard isFollowing else { return }
        
        let camera = UniversalMapCamera(
            center: location.coordinate,
            zoom: 17,
            bearing: heading,
            pitch: 50,
            animate: true
        )
        
        viewModel.updateCamera(to: camera)
    }
}
```

## Platform-Specific Considerations

### Google Maps

- Supports zoom levels 0-22
- Smooth bearing transitions
- Pitch up to ~60-67 degrees
- Animation timing controlled by Google Maps SDK

### MapLibre

- Supports zoom levels 0-22
- Bearing and pitch fully customizable
- Uses `acrossDistance` for zoom calculation
- More flexibility in animation curves

## Performance Tips

1. **Batch Updates**: Update camera once with all parameters instead of multiple times

   ```swift
   // Good
   let camera = UniversalMapCamera(center: coord, zoom: 15, bearing: 90, pitch: 45)
   viewModel.updateCamera(to: camera)
   
   // Avoid
   viewModel.updateCamera(to: UniversalMapCamera(center: coord))
   viewModel.updateCamera(to: UniversalMapCamera(center: coord, zoom: 15))
   viewModel.updateCamera(to: UniversalMapCamera(center: coord, zoom: 15, bearing: 90))
   ```

2. **Disable Animation for Frequent Updates**: When tracking, disable animation

   ```swift
   // Tracking mode - updates every second
   let camera = UniversalMapCamera(center: location, zoom: 17, animate: false)
   ```

3. **Limit Zoom Changes**: Avoid frequent zoom changes as they're computationally expensive

## SwiftUI Integration

```swift
struct MapCameraControls: View {
    @ObservedObject var viewModel: UniversalMapViewModel
    @State private var zoom: Double = 15
    @State private var pitch: Double = 0
    
    var body: some View {
        VStack {
            viewModel.makeMapView()
            
            VStack {
                HStack {
                    Text("Zoom")
                    Slider(value: $zoom, in: 5...20)
                }
                
                HStack {
                    Text("Pitch")
                    Slider(value: $pitch, in: 0...60)
                }
                
                Button("Update Camera") {
                    updateCamera()
                }
            }
            .padding()
        }
    }
    
    private func updateCamera() {
        guard let currentLocation = viewModel.mapProviderInstance.currentLocation else { return }
        
        let camera = UniversalMapCamera(
            center: currentLocation.coordinate,
            zoom: zoom,
            pitch: pitch,
            animate: true
        )
        
        viewModel.updateCamera(to: camera)
    }
}
```

## Best Practices

1. **Always Animate User Actions**: Use `animate: true` for user-initiated camera changes
2. **Skip Animation for Tracking**: Use `animate: false` for continuous tracking updates
3. **Sensible Zoom Levels**: Choose zoom levels appropriate for the content
4. **Smooth Bearing Changes**: Keep bearing changes < 180 degrees for smoother transitions
5. **Test on Device**: Camera animations may perform differently on simulators

## See Also

- [UniversalMapViewModel](docsUniversalMapViewModel.md)
- [MapProviderProtocol](docsMapProviderProtocol.md)
- [UniversalMapEdgeInsets](UniversalMapEdgeInsets.md)
