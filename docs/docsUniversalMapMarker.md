# UniversalMapMarker

`UniversalMarker` is the concrete implementation of `UniversalMapMarkerProtocol` that works seamlessly with both Google Maps and MapLibre.

## Overview

`UniversalMarker` is a versatile marker class that:
- Works with both Google Maps (`GMSMarker`) and MapLibre (`MLNAnnotation`)
- Supports custom UIViews for marker appearance
- Provides dynamic annotation view creation
- Handles coordinate updates and rotation
- Supports accessibility

## Class Declaration

```swift
public final class UniversalMarker: GMSMarker, MLNAnnotation, UniversalMapMarkerProtocol
```

## Properties

### id

```swift
public let id: String
```

Unique identifier for the marker.

### coordinate

```swift
dynamic public private(set) var coordinate: CLLocationCoordinate2D
```

The marker's geographic location. Marked as `dynamic` for KVO compatibility.

### annotationView

```swift
public let annotationView: AnnotationViewCompletionHandler?
```

Optional closure that creates a UIView for the marker dynamically.

**Type Definition:**
```swift
public typealias AnnotationViewCompletionHandler = (UniversalMarker) -> UIView?
```

### reuseIdentifier

```swift
public let reuseIdentifier: String?
```

Reuse identifier for optimizing marker view recycling.

### view

```swift
public let view: UIView?
```

The custom view to display for this marker.

## Initialization

### Init with Annotation View Handler

```swift
public init(
    id: String? = nil,
    coordinate: CLLocationCoordinate2D,
    annotationView: AnnotationViewCompletionHandler?,
    tintColor: UIColor = .red
)
```

Creates a marker with a dynamic view creation closure.

**Parameters:**
- `id`: Unique identifier (defaults to coordinate-based ID)
- `coordinate`: Geographic location
- `annotationView`: Closure that creates the view
- `tintColor`: Default tint color

**Example:**

```swift
let marker = UniversalMarker(
    id: "dynamic-marker",
    coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    annotationView: { marker in
        let view = UIImageView(image: UIImage(systemName: "star.fill"))
        view.tintColor = .yellow
        view.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        return view
    }
)
```

### Init with Custom View

```swift
public init(
    id: String? = nil,
    coordinate: CLLocationCoordinate2D,
    view: UIView,
    reuseIdentifier: String? = nil,
    tintColor: UIColor = .red
)
```

Creates a marker with a pre-configured custom view.

**Parameters:**
- `id`: Unique identifier (defaults to coordinate-based ID)
- `coordinate`: Geographic location
- `view`: Custom UIView for the marker
- `reuseIdentifier`: Optional reuse identifier
- `tintColor`: Default tint color

**Example:**

```swift
let iconView = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
iconView.tintColor = .red
iconView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)

let marker = UniversalMarker(
    id: "restaurant-123",
    coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    view: iconView
)

viewModel.addMarker(marker)
```

## Methods

### setGroundAnchor(_:)

```swift
@discardableResult
public func setGroundAnchor(_ point: CGPoint) -> Self
```

Sets the anchor point for the marker relative to its view.

**Parameters:**
- `point`: CGPoint where (0,0) is top-left and (1,1) is bottom-right

**Returns:** Self for method chaining

**Common Anchor Points:**
- `CGPoint(x: 0.5, y: 1.0)`: Bottom center (default for pins)
- `CGPoint(x: 0.5, y: 0.5)`: Center
- `CGPoint(x: 0, y: 0)`: Top-left
- `CGPoint(x: 1, y: 1)`: Bottom-right

**Example:**

```swift
marker.setGroundAnchor(CGPoint(x: 0.5, y: 1.0)) // Pin anchored at bottom
```

### set(coordinate:)

```swift
public func set(coordinate: CLLocationCoordinate2D)
```

Updates the marker's position.

**Example:**

```swift
let newLocation = CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4294)
marker.set(coordinate: newLocation)
viewModel.updateMarker(marker)
```

### set(heading:)

```swift
public func set(heading: CLLocationDirection)
```

Updates the marker's rotation/heading.

**Example:**

```swift
marker.set(heading: 135) // Rotate to southeast
viewModel.updateMarker(marker)
```

### updatePosition(coordinate:heading:)

```swift
public func updatePosition(coordinate: CLLocationCoordinate2D, heading: CLLocationDirection)
```

Updates both position and heading simultaneously.

**Example:**

```swift
marker.updatePosition(
    coordinate: vehicleLocation,
    heading: vehicleHeading
)
viewModel.updateMarker(marker)
```

## Usage Examples

### Basic Pin Marker

```swift
func createBasicMarker(at coordinate: CLLocationCoordinate2D) -> UniversalMarker {
    let pinView = UIImageView(image: UIImage(systemName: "mappin"))
    pinView.tintColor = .red
    pinView.frame = CGRect(x: 0, y: 0, width: 30, height: 40)
    
    let marker = UniversalMarker(
        id: "pin-\(UUID().uuidString)",
        coordinate: coordinate,
        view: pinView
    )
    
    marker.setGroundAnchor(CGPoint(x: 0.5, y: 1.0))
    
    return marker
}
```

### Custom Designed Marker

```swift
func createCustomMarker(restaurant: Restaurant) -> UniversalMarker {
    let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 70))
    
    // Background bubble
    let bubble = UIView(frame: CGRect(x: 5, y: 0, width: 50, height: 50))
    bubble.backgroundColor = .systemBlue
    bubble.layer.cornerRadius = 25
    bubble.layer.shadowColor = UIColor.black.cgColor
    bubble.layer.shadowOpacity = 0.3
    bubble.layer.shadowOffset = CGSize(width: 0, height: 2)
    containerView.addSubview(bubble)
    
    // Icon
    let icon = UIImageView(frame: CGRect(x: 15, y: 10, width: 30, height: 30))
    icon.image = UIImage(systemName: "fork.knife")
    icon.tintColor = .white
    containerView.addSubview(icon)
    
    // Pointer
    let pointer = UIView(frame: CGRect(x: 25, y: 50, width: 10, height: 20))
    pointer.backgroundColor = .systemBlue
    // Create triangle shape...
    containerView.addSubview(pointer)
    
    let marker = UniversalMarker(
        id: "restaurant-\(restaurant.id)",
        coordinate: restaurant.coordinate,
        view: containerView
    )
    
    marker.setGroundAnchor(CGPoint(x: 0.5, y: 1.0))
    
    return marker
}
```

### Vehicle Marker with Rotation

```swift
func createVehicleMarker(id: String, location: CLLocationCoordinate2D, heading: CLLocationDirection) -> UniversalMarker {
    let carView = UIImageView(image: UIImage(systemName: "car.fill"))
    carView.tintColor = .systemBlue
    carView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
    
    let marker = UniversalMarker(
        id: id,
        coordinate: location,
        view: carView
    )
    
    marker.setGroundAnchor(CGPoint(x: 0.5, y: 0.5)) // Center anchor for rotation
    marker.set(heading: heading)
    
    return marker
}

// Update vehicle position
func updateVehicle(marker: UniversalMarker, location: CLLocation) {
    marker.updatePosition(
        coordinate: location.coordinate,
        heading: location.course
    )
    viewModel.updateMarker(marker)
}
```

### Cluster-Style Marker

```swift
func createClusterMarker(count: Int, coordinate: CLLocationCoordinate2D) -> UniversalMarker {
    let size: CGFloat = 50
    let containerView = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
    
    // Circle background
    let circle = UIView(frame: containerView.bounds)
    circle.backgroundColor = count > 10 ? .systemRed : .systemBlue
    circle.layer.cornerRadius = size / 2
    containerView.addSubview(circle)
    
    // Count label
    let label = UILabel(frame: containerView.bounds)
    label.text = "\(count)"
    label.textColor = .white
    label.font = .systemFont(ofSize: 16, weight: .bold)
    label.textAlignment = .center
    containerView.addSubview(label)
    
    return UniversalMarker(
        id: "cluster-\(coordinate.identifier)",
        coordinate: coordinate,
        view: containerView
    )
}
```

### Animated Marker

```swift
func createPulsingMarker(at coordinate: CLLocationCoordinate2D) -> UniversalMarker {
    let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    
    let dot = UIView(frame: CGRect(x: 10, y: 10, width: 20, height: 20))
    dot.backgroundColor = .systemBlue
    dot.layer.cornerRadius = 10
    containerView.addSubview(dot)
    
    // Pulse animation
    let pulse = CABasicAnimation(keyPath: "transform.scale")
    pulse.fromValue = 1.0
    pulse.toValue = 1.3
    pulse.duration = 1.0
    pulse.autoreverses = true
    pulse.repeatCount = .infinity
    dot.layer.add(pulse, forKey: "pulse")
    
    return UniversalMarker(
        id: "pulse-\(UUID().uuidString)",
        coordinate: coordinate,
        view: containerView
    )
}
```

### Dynamic Marker with Closure

```swift
func createDynamicMarker(location: Location) -> UniversalMarker {
    UniversalMarker(
        id: "loc-\(location.id)",
        coordinate: location.coordinate,
        annotationView: { marker in
            // View created dynamically when needed
            let view = UIImageView(image: location.categoryIcon)
            view.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
            view.tintColor = location.categoryColor
            return view
        }
    )
}
```

## Advanced Examples

### Marker with Badge

```swift
func createMarkerWithBadge(title: String, badge: String?, coordinate: CLLocationCoordinate2D) -> UniversalMarker {
    let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 60))
    
    // Main marker
    let marker = UIImageView(frame: CGRect(x: 10, y: 10, width: 30, height: 40))
    marker.image = UIImage(systemName: "mappin.circle.fill")
    marker.tintColor = .systemRed
    containerView.addSubview(marker)
    
    if let badge = badge {
        // Badge
        let badgeView = UILabel(frame: CGRect(x: 25, y: 0, width: 25, height: 25))
        badgeView.text = badge
        badgeView.textColor = .white
        badgeView.font = .systemFont(ofSize: 12, weight: .bold)
        badgeView.textAlignment = .center
        badgeView.backgroundColor = .systemBlue
        badgeView.layer.cornerRadius = 12.5
        badgeView.clipsToBounds = true
        containerView.addSubview(badgeView)
    }
    
    return UniversalMarker(
        id: "badge-\(title)",
        coordinate: coordinate,
        view: containerView
    )
}
```

### Image Marker from Network

```swift
func createImageMarker(imageURL: URL, coordinate: CLLocationCoordinate2D) async -> UniversalMarker {
    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    imageView.contentMode = .scaleAspectFill
    imageView.layer.cornerRadius = 20
    imageView.clipsToBounds = true
    
    // Placeholder
    imageView.backgroundColor = .systemGray
    
    // Load image asynchronously
    Task {
        if let (data, _) = try? await URLSession.shared.data(from: imageURL),
           let image = UIImage(data: data) {
            await MainActor.run {
                imageView.image = image
            }
        }
    }
    
    return UniversalMarker(
        id: "image-\(UUID().uuidString)",
        coordinate: coordinate,
        view: imageView
    )
}
```

## Best Practices

1. **Reuse IDs**: For updatable markers, use consistent IDs
   ```swift
   let marker = UniversalMarker(id: "vehicle-\(vehicleId)", ...)
   ```

2. **Set Ground Anchor**: Always set appropriate anchor for your marker type
   ```swift
   marker.setGroundAnchor(CGPoint(x: 0.5, y: 1.0)) // Bottom-center for pins
   ```

3. **Appropriate View Sizes**: Keep marker views reasonably sized
   ```swift
   // Good: 20-50 points
   let view = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
   
   // Avoid: Very large views
   ```

4. **Accessibility**: Set accessibility labels
   ```swift
   marker.accessibilityLabel = "Restaurant: \(name)"
   ```

5. **Memory Efficiency**: For many markers, use simple views
   ```swift
   // Simple view for bulk markers
   let simplePin = UIImageView(image: UIImage(systemName: "mappin"))
   ```

## Performance Considerations

- **View Complexity**: Simpler views perform better with many markers
- **Reuse Identifiers**: Help with view recycling (especially on MapLibre)
- **Visibility Culling**: Google Maps provider automatically culls off-screen markers
- **Update Batching**: Update multiple markers together when possible

## See Also

- [UniversalMapMarkerProtocol](UniversalMapMarkerProtocol.md)
- [UniversalMapViewModel](UniversalMapViewModel.md)
- [Marker Visibility Management](MarkerVisibilityManagement.md)
