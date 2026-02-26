# UniversalMapMarkerProtocol

`UniversalMapMarkerProtocol` defines the interface for map markers in IMap. It ensures markers can work consistently across different map providers while maintaining type safety and Swift Concurrency compatibility.

## Overview

This protocol allows you to create custom marker types that work with both Google Maps and MapLibre. All markers must provide:
- A unique identifier
- A coordinate location
- A rotation/heading
- Conformance to `Identifiable`, `Sendable`, and `Hashable`

## Protocol Declaration

```swift
public protocol UniversalMapMarkerProtocol: Identifiable, Sendable, Hashable {
    var id: String { get }
    var coordinate: CLLocationCoordinate2D { get }
    var rotation: CLLocationDirection { get }
}
```

## Required Properties

### id

```swift
var id: String { get }
```

A unique identifier for the marker. This is used to:
- Track markers in collections
- Update or remove specific markers
- Handle marker tap events

**Best Practice:** Use UUID strings or meaningful identifiers based on your data model.

### coordinate

```swift
var coordinate: CLLocationCoordinate2D { get }
```

The geographic location where the marker should be displayed.

**Type:** `CLLocationCoordinate2D` from CoreLocation

### rotation

```swift
var rotation: CLLocationDirection { get }
```

The rotation angle of the marker in degrees, measured clockwise from north.

**Type:** `CLLocationDirection` (alias for `Double`)

**Range:** 0-360 degrees
- `0` or `360`: North
- `90`: East
- `180`: South
- `270`: West

## Conformance Requirements

### Identifiable

The protocol inherits from `Identifiable`, which requires an `id` property. Since `UniversalMapMarkerProtocol` already defines `id` as a `String`, this requirement is automatically satisfied.

### Sendable

Markers must be `Sendable` to support Swift Concurrency. This ensures they can be safely passed between different execution contexts.

**Implications:**
- All properties should be immutable or thread-safe
- Reference types should be carefully managed
- Value types are preferred

### Hashable

Markers must be `Hashable` to allow them to be stored in sets and used as dictionary keys.

**Implementation Note:** If you're creating a custom marker type, you typically need to implement `hash(into:)` or let the compiler synthesize it.

## Conforming Types

IMap provides a built-in conforming type:

### UniversalMarker

```swift
public final class UniversalMarker: GMSMarker, MLNAnnotation, UniversalMapMarkerProtocol
```

`UniversalMarker` is a concrete implementation that works with both Google Maps and MapLibre.

## Example: Creating a Basic Marker

```swift
// Using the built-in UniversalMarker
let markerView = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
markerView.tintColor = .red
markerView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)

let marker = UniversalMarker(
    id: "restaurant-1",
    coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    view: markerView
)

viewModel.addMarker(marker)
```

## Example: Custom Marker Type

You can create your own marker types by conforming to the protocol:

```swift
struct LocationPin: UniversalMapMarkerProtocol {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let rotation: CLLocationDirection
    let title: String
    let category: String
    
    init(
        id: String,
        coordinate: CLLocationCoordinate2D,
        rotation: CLLocationDirection = 0,
        title: String,
        category: String
    ) {
        self.id = id
        self.coordinate = coordinate
        self.rotation = rotation
        self.title = title
        self.category = category
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: LocationPin, rhs: LocationPin) -> Bool {
        lhs.id == rhs.id
    }
}

// Usage
let pin = LocationPin(
    id: "cafe-\(UUID().uuidString)",
    coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    rotation: 45,
    title: "Blue Bottle Coffee",
    category: "Cafe"
)

viewModel.addMarker(pin)
```

## Example: Vehicle Marker with Rotation

```swift
struct VehicleMarker: UniversalMapMarkerProtocol {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let rotation: CLLocationDirection
    let vehicleType: VehicleType
    let speed: Double
    
    enum VehicleType {
        case car, bike, scooter
    }
    
    init(
        vehicleId: String,
        coordinate: CLLocationCoordinate2D,
        heading: CLLocationDirection,
        vehicleType: VehicleType,
        speed: Double
    ) {
        self.id = vehicleId
        self.coordinate = coordinate
        self.rotation = heading
        self.vehicleType = vehicleType
        self.speed = speed
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: VehicleMarker, rhs: VehicleMarker) -> Bool {
        lhs.id == rhs.id
    }
}

// Usage - marker will be rotated to match vehicle heading
let vehicle = VehicleMarker(
    vehicleId: "vehicle-123",
    coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    heading: 135, // Southeast direction
    vehicleType: .car,
    speed: 35.5
)

viewModel.addMarker(vehicle)
```

## Updating Markers

To update a marker's position or rotation, use the `updateMarker` method:

```swift
// Update marker position
var updatedMarker = existingMarker
updatedMarker.coordinate = newCoordinate
updatedMarker.rotation = newHeading

viewModel.updateMarker(updatedMarker)
```

For `UniversalMarker` specifically:

```swift
let marker = UniversalMarker(...)
viewModel.addMarker(marker)

// Later, update position and rotation
marker.set(coordinate: newCoordinate)
marker.set(heading: newHeading)
viewModel.updateMarker(marker)
```

## Performance Considerations

### Marker Visibility Culling

IMap (especially with Google Maps) implements automatic visibility culling:
- Only markers within the visible map region are rendered
- Markers outside the viewport are kept in memory but not rendered
- This improves performance with large numbers of markers

**Recommendation:** You can add thousands of markers, but only visible ones impact rendering performance.

### Memory Management

For value types (structs):
```swift
struct MyMarker: UniversalMapMarkerProtocol {
    // Value type - automatically copied
}
```

For reference types (classes):
```swift
class MyMarker: UniversalMapMarkerProtocol {
    // Be mindful of retain cycles
    // Implement deinit if needed
}
```

## Helper Extension: CLLocationCoordinate2D

The framework includes a helpful extension:

```swift
extension CLLocationCoordinate2D {
    var identifier: String {
        "\(latitude),\(longitude)"
    }
}
```

This can be used to generate IDs based on coordinates:

```swift
let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
let marker = UniversalMarker(
    id: coordinate.identifier, // "37.7749,-122.4194"
    coordinate: coordinate,
    view: markerView
)
```

## Best Practices

1. **Unique IDs**: Always ensure marker IDs are unique within your map
   ```swift
   let id = "marker-\(UUID().uuidString)"
   ```

2. **Meaningful IDs**: Use IDs that represent your data model
   ```swift
   let id = "restaurant-\(restaurant.id)"
   ```

3. **Rotation for Direction**: Use the `rotation` property to show direction
   ```swift
   let marker = VehicleMarker(
       id: "car-1",
       coordinate: location,
       heading: vehicle.heading, // Points in direction of travel
       vehicleType: .car
   )
   ```

4. **Immutability**: Prefer immutable properties for thread safety
   ```swift
   struct Marker: UniversalMapMarkerProtocol {
       let id: String  // Not var
       let coordinate: CLLocationCoordinate2D
       let rotation: CLLocationDirection
   }
   ```

5. **Batch Operations**: When adding many markers, consider batching
   ```swift
   let markers = locations.map { location in
       UniversalMarker(
           id: location.id,
           coordinate: location.coordinate,
           view: createMarkerView(for: location)
       )
   }
   
   markers.forEach { viewModel.addMarker($0) }
   ```

## Limitations

- **Custom Views**: While `UniversalMarker` supports custom UIViews, custom protocol conformances should be careful about view lifecycle
- **Animations**: Marker animations are handled by the underlying map provider and may differ between Google Maps and MapLibre
- **Z-Index**: Rendering order is provider-dependent unless explicitly managed

## See Also

- [UniversalMarker](docsUniversalMapMarker.md)
- [MapProviderProtocol](docsMapProviderProtocol.md)
- [UniversalMapViewModel](docsUniversalMapViewModel.md)
- [Marker Visibility Management](docsMarkerVisibilityManagement.md)
