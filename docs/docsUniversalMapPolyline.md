# UniversalMapPolyline

`UniversalMapPolyline` represents a series of connected line segments on the map, typically used to display routes, paths, or boundaries.

## Overview

Polylines are fundamental to displaying routes and paths on maps. `UniversalMapPolyline` provides a provider-agnostic way to:
- Draw routes on the map
- Customize appearance (color, width)
- Animate drawing
- Calculate distances
- Focus camera on routes

## Structure Declaration

```swift
public struct UniversalMapPolyline: Identifiable
```

## Properties

### id

```swift
public let id: String
```

Unique identifier for the polyline. Used to update or remove specific polylines.

**Default:** `UUID().uuidString` (auto-generated)

### coordinates

```swift
public var coordinates: [CLLocationCoordinate2D]
```

Array of coordinates that form the polyline path.

**Requirements:**
- Minimum 2 coordinates to draw a line
- Coordinates are connected in order
- More coordinates = smoother curves

### color

```swift
public var color: UIColor
```

The color of the polyline.

**Default:** `.blue`

**Example Colors:**
```swift
.blue       // Standard blue
.red        // Red route
.systemGreen // Adaptive green
UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0) // Custom color
```

### width

```swift
public var width: CGFloat
```

The width/thickness of the polyline in points.

**Default:** `3.0`

**Recommendations:**
- `2.0-3.0`: Thin lines for background routes
- `5.0-7.0`: Standard route visualization
- `8.0+`: Highlighted or primary routes

### geodesic

```swift
public var geodesic: Bool
```

Whether the polyline should follow the curvature of the Earth.

**Default:** `true`

**When to use:**
- `true`: For long-distance routes (flights, shipping)
- `false`: For local routes where Earth's curvature is negligible

### title

```swift
public var title: String?
```

Optional title for the polyline.

**Default:** `nil`

## Initialization

### Standard Initializer

```swift
public init(
    id: String = UUID().uuidString,
    coordinates: [CLLocationCoordinate2D],
    color: UIColor = .blue,
    width: CGFloat = 3.0,
    geodesic: Bool = true,
    title: String? = nil
)
```

**Example:**

```swift
let route = UniversalMapPolyline(
    id: "route-home-to-work",
    coordinates: [
        CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4294),
        CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.4394)
    ],
    color: .systemBlue,
    width: 5.0,
    geodesic: true,
    title: "Morning Commute"
)
```

### From Route Coordinates

```swift
public static func fromRouteCoordinates(_ routeCoords: [RouteDataCoordinate]) -> UniversalMapPolyline
```

Creates a polyline from an array of `RouteDataCoordinate` objects.

**Example:**

```swift
let routeData: [RouteDataCoordinate] = fetchRouteData()
let polyline = UniversalMapPolyline.fromRouteCoordinates(routeData)
```

## Computed Properties

### distance

```swift
public var distance: CLLocationDistance
```

The total distance of the polyline in meters.

**Calculation:** Sums the distances between consecutive coordinate pairs.

**Example:**

```swift
let polyline = UniversalMapPolyline(
    coordinates: routeCoordinates,
    color: .blue
)

let distanceInMeters = polyline.distance
let distanceInKm = distanceInMeters / 1000
let distanceInMiles = distanceInMeters / 1609.34

print("Route distance: \(distanceInKm) km")
```

## Usage Examples

### Basic Route

```swift
let coordinates = [
    CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4294),
    CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.4394)
]

let route = UniversalMapPolyline(coordinates: coordinates)
viewModel.addPolyline(route)
```

### Animated Route Drawing

```swift
let route = UniversalMapPolyline(
    id: "animated-route",
    coordinates: coordinates,
    color: .systemBlue,
    width: 6.0
)

// Polyline will be drawn with animation
viewModel.addPolyline(route, animated: true)
```

### Multiple Routes with Different Styles

```swift
// Primary route - thick and blue
let primaryRoute = UniversalMapPolyline(
    id: "primary",
    coordinates: primaryCoordinates,
    color: .systemBlue,
    width: 7.0,
    title: "Fastest Route"
)

// Alternative route - thinner and gray
let alternativeRoute = UniversalMapPolyline(
    id: "alternative",
    coordinates: alternativeCoordinates,
    color: .systemGray,
    width: 4.0,
    title: "Alternative Route"
)

viewModel.addPolyline(primaryRoute)
viewModel.addPolyline(alternativeRoute)
```

### Color-Coded by Traffic

```swift
func createTrafficRoute(segments: [(coordinates: [CLLocationCoordinate2D], traffic: TrafficLevel)]) {
    for (index, segment) in segments.enumerated() {
        let color: UIColor = switch segment.traffic {
        case .clear: .systemGreen
        case .moderate: .systemOrange
        case .heavy: .systemRed
        }
        
        let polyline = UniversalMapPolyline(
            id: "traffic-segment-\(index)",
            coordinates: segment.coordinates,
            color: color,
            width: 6.0
        )
        
        viewModel.addPolyline(polyline)
    }
}
```

### Long-Distance Flight Path

```swift
let flightPath = UniversalMapPolyline(
    id: "flight-sfo-lhr",
    coordinates: [
        CLLocationCoordinate2D(latitude: 37.6213, longitude: -122.3790), // SFO
        CLLocationCoordinate2D(latitude: 51.4700, longitude: -0.4543)     // LHR
    ],
    color: .systemPurple,
    width: 3.0,
    geodesic: true, // Important for long distances!
    title: "SFO → LHR"
)

viewModel.addPolyline(flightPath)
```

## Updating Polylines

### Update Entire Polyline

```swift
var route = existingRoute
route.coordinates = newCoordinates
route.color = .systemRed
route.width = 8.0

viewModel.updatePolyline(route, animated: true)
```

### Update Only Coordinates

```swift
viewModel.updatePolyline(
    id: "route-1",
    coordinates: updatedCoordinates,
    animated: true
)
```

### Batch Update Routes

```swift
let newRoutes = [
    UniversalMapPolyline(id: "route-1", coordinates: coords1, color: .blue),
    UniversalMapPolyline(id: "route-2", coordinates: coords2, color: .red),
]

// Removes routes not in newRoutes array, updates existing, adds new
viewModel.setOrUpdate(polylines: newRoutes, animated: true)
```

## Focusing on Polylines

### Focus Camera on Route

```swift
viewModel.addPolyline(route)

// Automatically adjust camera to show entire route
await viewModel.focusOnPolyline(
    id: route.id,
    padding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
    animated: true
)
```

### Focus with Custom Padding

```swift
// More padding at bottom for UI elements
await viewModel.focusOnPolyline(
    id: route.id,
    padding: UIEdgeInsets(top: 100, left: 50, bottom: 300, right: 50),
    animated: true
)
```

## Distance Calculations

```swift
let route = UniversalMapPolyline(coordinates: coordinates)

// Total distance in meters
let meters = route.distance

// Convert to other units
let kilometers = meters / 1000
let miles = meters / 1609.34
let feet = meters * 3.28084

print("Route: \(kilometers) km (\(miles) mi)")
```

## Performance Considerations

### Coordinate Count

- **< 100 coordinates**: Excellent performance
- **100-1000 coordinates**: Good performance, may see slight delay
- **1000+ coordinates**: Consider simplification algorithms

**Tip:** For very detailed routes, consider simplifying using algorithms like Douglas-Peucker.

### Animation Performance

Animated polyline drawing performs well up to ~500 coordinates. For larger routes:

```swift
if coordinates.count > 500 {
    // Don't animate very long routes
    viewModel.addPolyline(polyline, animated: false)
} else {
    viewModel.addPolyline(polyline, animated: true)
}
```

### Memory Efficiency

Each polyline stores its coordinates in memory. For route tracking with frequent updates:

```swift
// Update existing polyline instead of creating new ones
viewModel.updatePolyline(id: "tracking-route", coordinates: newPath, animated: true)
```

## Styling Tips

### Dark Mode Support

```swift
@Environment(\.colorScheme) var colorScheme

var routeColor: UIColor {
    colorScheme == .dark ? .systemBlue : UIColor.blue.withAlphaComponent(0.8)
}

let route = UniversalMapPolyline(
    coordinates: coordinates,
    color: routeColor
)
```

### Adaptive Width

```swift
func polylineWidth(for distance: CLLocationDistance) -> CGFloat {
    switch distance {
    case 0..<1000: return 6.0      // Short routes: thicker
    case 1000..<10000: return 5.0  // Medium routes: medium
    default: return 3.0             // Long routes: thinner
    }
}

let route = UniversalMapPolyline(
    coordinates: coordinates,
    width: polylineWidth(for: totalDistance)
)
```

### Multiple Colors for Different Types

```swift
enum RouteType {
    case driving, walking, cycling, transit
    
    var color: UIColor {
        switch self {
        case .driving: return .systemBlue
        case .walking: return .systemGreen
        case .cycling: return .systemOrange
        case .transit: return .systemPurple
        }
    }
    
    var width: CGFloat {
        switch self {
        case .driving: return 6.0
        case .walking: return 4.0
        case .cycling: return 5.0
        case .transit: return 5.0
        }
    }
}

func createRoute(type: RouteType, coordinates: [CLLocationCoordinate2D]) -> UniversalMapPolyline {
    UniversalMapPolyline(
        coordinates: coordinates,
        color: type.color,
        width: type.width
    )
}
```

## Removing Polylines

```swift
// Remove specific polyline
viewModel.removePolyline(withId: "route-1")

// Remove all polylines
viewModel.clearAllPolylines()
```

## Advanced Usage: Real-Time Route Updates

```swift
class LiveRouteTracker {
    private let viewModel: UniversalMapViewModel
    private let routeId = "live-route"
    private var pathCoordinates: [CLLocationCoordinate2D] = []
    
    func addLocationToRoute(_ coordinate: CLLocationCoordinate2D) {
        pathCoordinates.append(coordinate)
        
        let polyline = UniversalMapPolyline(
            id: routeId,
            coordinates: pathCoordinates,
            color: .systemBlue,
            width: 5.0
        )
        
        // Update existing or add new
        viewModel.updatePolyline(polyline, animated: true)
    }
}
```

## Best Practices

1. **Reuse IDs**: Use consistent IDs to update routes rather than removing and re-adding
2. **Simplify Long Routes**: For routes with thousands of points, simplify for better performance
3. **Geodesic for Long Distances**: Always use `geodesic: true` for routes > 100km
4. **Appropriate Width**: Match width to zoom level and route importance
5. **Color Contrast**: Ensure polyline color contrasts with map style
6. **Batch Updates**: Update multiple polylines together when possible

## See Also

- [UniversalMapViewModel](UniversalMapViewModel.md)
- [RouteTrackingManager](RouteTrackingManager.md)
- [MapProviderProtocol](MapProviderProtocol.md)
