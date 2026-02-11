# RouteTrackingManager

`RouteTrackingManager` provides intelligent route tracking functionality, allowing you to monitor movement along a predefined route and determine if a location is on or off the expected path.

## Overview

This manager is essential for navigation and delivery applications where you need to:
- Snap GPS coordinates to the nearest point on a route
- Determine if a vehicle/user is following the route
- Calculate remaining path from current position
- Handle GPS noise and inaccuracies

## Class Declaration

```swift
public class RouteTrackingManager
```

## Initialization

```swift
public init(routeCoordinates: [CLLocationCoordinate2D], threshold: CLLocationDistance = 30)
```

**Parameters:**
- `routeCoordinates`: Array of coordinates representing the full route path
- `threshold`: Maximum distance in meters from the route to be considered "on track" (default: 30 meters)

**Example:**

```swift
let route = [
    CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4294),
    CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.4394)
]

let tracker = RouteTrackingManager(
    routeCoordinates: route,
    threshold: 50 // 50 meters tolerance
)
```

## Tracking Status

### RouteTrackingStatus

```swift
public enum RouteTrackingStatus {
    case onTrack(snappedLocation: CLLocationCoordinate2D, remainingPath: [CLLocationCoordinate2D])
    case outOfRoute
}
```

**Cases:**

#### onTrack

The location is within the threshold distance of the route.

**Associated Values:**
- `snappedLocation`: The closest point on the route to the actual location
- `remainingPath`: Array of coordinates from the snapped location to the route end

#### outOfRoute

The location is too far from the route (beyond the threshold).

## Methods

### updateDriverLocation(_:)

```swift
public func updateDriverLocation(_ location: CLLocationCoordinate2D) -> RouteTrackingStatus
```

Updates the tracking with a new location and determines the route status.

**Parameters:**
- `location`: The current location to check

**Returns:** `RouteTrackingStatus` indicating if on or off route

**Algorithm:**
1. Checks all route segments
2. Calculates perpendicular distance to each segment
3. Finds the closest point
4. Snaps to that point if within threshold
5. Returns remaining route from that point

**Example:**

```swift
let tracker = RouteTrackingManager(routeCoordinates: routeCoordinates)

// Update with current location
let currentLocation = CLLocationCoordinate2D(latitude: 37.7800, longitude: -122.4200)

switch tracker.updateDriverLocation(currentLocation) {
case .onTrack(let snappedLocation, let remainingPath):
    print("On route! Snapped to: \(snappedLocation)")
    print("Remaining waypoints: \(remainingPath.count)")
    
    // Update map with remaining route
    let remainingPolyline = UniversalMapPolyline(
        id: "remaining-route",
        coordinates: remainingPath,
        color: .systemBlue
    )
    viewModel.updatePolyline(remainingPolyline)
    
case .outOfRoute:
    print("Off route! Please recalculate.")
    // Show rerouting UI
}
```

## Integration Examples

### Basic Navigation

```swift
class NavigationManager {
    private let viewModel: UniversalMapViewModel
    private var routeTracker: RouteTrackingManager?
    
    func startNavigation(route: [CLLocationCoordinate2D]) {
        // Initialize tracker
        routeTracker = RouteTrackingManager(
            routeCoordinates: route,
            threshold: 30
        )
        
        // Show full route
        let polyline = UniversalMapPolyline(
            id: "full-route",
            coordinates: route,
            color: .systemBlue,
            width: 6.0
        )
        viewModel.addPolyline(polyline)
        
        // Start location updates
        startLocationUpdates()
    }
    
    func handleLocationUpdate(_ location: CLLocation) {
        guard let tracker = routeTracker else { return }
        
        let status = tracker.updateDriverLocation(location.coordinate)
        
        switch status {
        case .onTrack(let snapped, let remaining):
            updateRemainingRoute(remaining)
            updateUserPosition(snapped)
            
        case .outOfRoute:
            handleOffRoute()
        }
    }
    
    private func updateRemainingRoute(_ coordinates: [CLLocationCoordinate2D]) {
        let remaining = UniversalMapPolyline(
            id: "remaining",
            coordinates: coordinates,
            color: .systemBlue,
            width: 6.0
        )
        viewModel.updatePolyline(remaining, animated: true)
    }
    
    private func handleOffRoute() {
        // Show alert or recalculate route
        showReroutingAlert()
    }
}
```

### Delivery Tracking

```swift
class DeliveryTracker: ObservableObject {
    @Published var isOnRoute = true
    @Published var distanceRemaining: CLLocationDistance = 0
    @Published var estimatedArrival: Date?
    
    private let tracker: RouteTrackingManager
    private let averageSpeed: CLLocationDistance = 10 // m/s
    
    init(deliveryRoute: [CLLocationCoordinate2D]) {
        self.tracker = RouteTrackingManager(
            routeCoordinates: deliveryRoute,
            threshold: 50 // Larger threshold for delivery
        )
    }
    
    func updateLocation(_ location: CLLocationCoordinate2D) {
        let status = tracker.updateDriverLocation(location)
        
        switch status {
        case .onTrack(_, let remainingPath):
            isOnRoute = true
            distanceRemaining = calculateDistance(remainingPath)
            estimatedArrival = Date().addingTimeInterval(distanceRemaining / averageSpeed)
            
        case .outOfRoute:
            isOnRoute = false
            estimatedArrival = nil
        }
    }
    
    private func calculateDistance(_ path: [CLLocationCoordinate2D]) -> CLLocationDistance {
        let polyline = UniversalMapPolyline(coordinates: path)
        return polyline.distance
    }
}
```

### Live Route Progress Visualization

```swift
class RouteProgressManager {
    private let viewModel: UniversalMapViewModel
    private let tracker: RouteTrackingManager
    
    init(viewModel: UniversalMapViewModel, route: [CLLocationCoordinate2D]) {
        self.viewModel = viewModel
        self.tracker = RouteTrackingManager(routeCoordinates: route)
        
        // Show full route in gray
        let fullRoute = UniversalMapPolyline(
            id: "full-route",
            coordinates: route,
            color: .systemGray,
            width: 4.0
        )
        viewModel.addPolyline(fullRoute)
    }
    
    func updateProgress(location: CLLocationCoordinate2D) {
        let status = tracker.updateDriverLocation(location)
        
        switch status {
        case .onTrack(let snapped, let remaining):
            // Show remaining route in blue
            let remainingPolyline = UniversalMapPolyline(
                id: "remaining",
                coordinates: remaining,
                color: .systemBlue,
                width: 6.0
            )
            viewModel.updatePolyline(remainingPolyline, animated: true)
            
            // Update driver marker at snapped location
            updateDriverMarker(at: snapped)
            
        case .outOfRoute:
            // Remove remaining route visualization
            viewModel.removePolyline(withId: "remaining")
        }
    }
    
    private func updateDriverMarker(at coordinate: CLLocationCoordinate2D) {
        // Update driver position on map
    }
}
```

### Multi-Stop Route Tracking

```swift
class MultiStopTracker {
    private var currentLegTracker: RouteTrackingManager?
    private let allStops: [CLLocationCoordinate2D]
    private var currentStopIndex = 0
    
    init(stops: [CLLocationCoordinate2D], routeLegs: [[CLLocationCoordinate2D]]) {
        self.allStops = stops
        
        // Start with first leg
        if let firstLeg = routeLegs.first {
            currentLegTracker = RouteTrackingManager(routeCoordinates: firstLeg)
        }
    }
    
    func updateLocation(_ location: CLLocationCoordinate2D) {
        guard let tracker = currentLegTracker else { return }
        
        let status = tracker.updateDriverLocation(location)
        
        switch status {
        case .onTrack(let snapped, let remaining):
            // Check if approaching destination
            if remaining.count < 3 {
                checkIfArrivedAtStop(location)
            }
            
        case .outOfRoute:
            // Might have arrived or detoured
            checkIfArrivedAtStop(location)
        }
    }
    
    private func checkIfArrivedAtStop(_ location: CLLocationCoordinate2D) {
        let currentStop = allStops[currentStopIndex]
        let distance = location.distance(to: currentStop)
        
        if distance < 30 { // Within 30 meters
            advanceToNextStop()
        }
    }
    
    private func advanceToNextStop() {
        currentStopIndex += 1
        // Load next route leg tracker
    }
}

extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return from.distance(from: to)
    }
}
```

## Advanced Configuration

### Custom Threshold Based on Conditions

```swift
func createAdaptiveTracker(route: [CLLocationCoordinate2D], 
                          speed: CLLocationSpeed,
                          accuracy: CLLocationAccuracy) -> RouteTrackingManager {
    // Larger threshold at higher speeds
    let speedThreshold = min(speed * 2, 100) // Up to 100m
    
    // Larger threshold with poor GPS accuracy
    let accuracyThreshold = max(accuracy * 1.5, 20) // At least 20m
    
    // Use the larger of the two
    let threshold = max(speedThreshold, accuracyThreshold)
    
    return RouteTrackingManager(
        routeCoordinates: route,
        threshold: threshold
    )
}
```

### Urban vs Highway Tracking

```swift
enum RouteType {
    case urban
    case highway
    
    var trackingThreshold: CLLocationDistance {
        switch self {
        case .urban:
            return 30  // Tighter tracking in cities
        case .highway:
            return 75  // More lenient on highways
        }
    }
}

func createTracker(for routeType: RouteType, 
                  coordinates: [CLLocationCoordinate2D]) -> RouteTrackingManager {
    RouteTrackingManager(
        routeCoordinates: coordinates,
        threshold: routeType.trackingThreshold
    )
}
```

## Performance Considerations

### Coordinate Simplification

For routes with many waypoints, consider simplifying:

```swift
// Only use every Nth coordinate for tracking
func simplifyRoute(_ coordinates: [CLLocationCoordinate2D], keepEvery n: Int) -> [CLLocationCoordinate2D] {
    stride(from: 0, to: coordinates.count, by: n).map { coordinates[$0] }
}

let simplifiedRoute = simplifyRoute(fullRoute, keepEvery: 3)
let tracker = RouteTrackingManager(routeCoordinates: simplifiedRoute)
```

### Caching

The tracker caches `MKMapPoint` conversions for better performance:

```swift
// Internal implementation uses cached map points
private let routePoints: [MKMapPoint] // Calculated once
```

## Algorithm Details

The manager uses a **perpendicular distance to segment** algorithm:

1. For each segment in the route
2. Calculate the perpendicular distance from the location to the segment
3. Find the closest point on the segment
4. Clamp the point to the segment (not extended line)
5. Return the minimum distance across all segments

This is more accurate than simple point-to-point distance.

## Limitations

- **Route must have at least 2 points** - Single point routes will only check distance to that point
- **Memory usage** - Stores all route coordinates plus MKMapPoint conversions
- **No route recalculation** - Only tracks against the original route

## Error Handling

```swift
let tracker = RouteTrackingManager(routeCoordinates: route)

if route.count < 2 {
    print("Warning: Route has fewer than 2 points")
}

let status = tracker.updateDriverLocation(location)

switch status {
case .onTrack(_, let remaining):
    if remaining.isEmpty {
        print("Reached destination!")
    }
    
case .outOfRoute:
    print("User is off route")
    // Trigger recalculation
}
```

## Best Practices

1. **Appropriate Threshold**: 
   - City driving: 20-30 meters
   - Highway: 50-100 meters
   - Walking: 10-20 meters

2. **Update Frequency**: Update every 3-5 seconds, not every GPS update

3. **Battery Efficiency**: Use significant location changes when possible

4. **Visualize Snapped Location**: Show users their snapped position, not raw GPS

5. **Handle Edge Cases**: Route start, route end, loops

## See Also

- [UniversalMapPolyline](UniversalMapPolyline.md)
- [UniversalMapViewModel](UniversalMapViewModel.md)
- [MapProviderProtocol](MapProviderProtocol.md)
