# MapProviderProtocol

`MapProviderProtocol` defines the common interface that all map providers must implement. This protocol enables the abstraction layer that allows IMap to work with different mapping backends.

## Overview

The protocol defines all the operations that can be performed on a map, regardless of whether it's Google Maps or MapLibre. This enables:
- Provider-agnostic code in your application
- Easy switching between providers
- Consistent behavior across different map implementations

## Protocol Declaration

```swift
public protocol MapProviderProtocol: NSObject
```

## Required Initializer

```swift
init()
```

Creates a new instance of the map provider.

## Properties

### currentLocation

```swift
var currentLocation: CLLocation? { get }
```

The user's current location, if available.

### markers

```swift
var markers: [String: any UniversalMapMarkerProtocol] { get }
```

Dictionary of all markers currently rendered on the map, keyed by their IDs.

### polylines

```swift
var polylines: [String: UniversalMapPolyline] { get }
```

Dictionary of all polylines currently on the map, keyed by their IDs.

## Camera Management

### updateCamera(to:)

```swift
func updateCamera(to camera: UniversalMapCamera)
```

Updates the map camera to a new position.

**Parameters:**
- `camera`: The target camera configuration

**Example:**

```swift
let camera = UniversalMapCamera(
    center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    zoom: 15,
    animate: true
)
provider.updateCamera(to: camera)
```

### focusMap(on:zoom:animated:)

```swift
func focusMap(on coordinate: CLLocationCoordinate2D, zoom: Double?, animated: Bool)
```

Focuses the map on a specific coordinate with optional zoom level.

### focusOnPolyline(id:padding:animated:)

```swift
func focusOnPolyline(id: String, padding: UIEdgeInsets, animated: Bool)
```

Adjusts the camera to show an entire polyline within the viewport.

### focusOnPolyline(id:animated:)

```swift
func focusOnPolyline(id: String, animated: Bool)
```

Adjusts the camera to show an entire polyline with default padding.

### focusOn(coordinates:padding:animated:)

```swift
func focusOn(coordinates: [CLLocationCoordinate2D], padding: CGFloat, animated: Bool)
```

Adjusts the camera to show multiple coordinates with uniform padding.

### focusOn(coordinates:edges:animated:)

```swift
func focusOn(coordinates: [CLLocationCoordinate2D], edges: UIEdgeInsets, animated: Bool)
```

Adjusts the camera to show multiple coordinates with custom edge insets.

## Marker Management

### addMarker(_:)

```swift
func addMarker(_ marker: any UniversalMapMarkerProtocol)
```

Adds a marker to the map.

**Parameters:**
- `marker`: The marker to add (must conform to `UniversalMapMarkerProtocol`)

### marker(byId:)

```swift
func marker(byId id: String) -> (any UniversalMapMarkerProtocol)?
```

Retrieves a marker by its ID.

**Returns:** The marker if found, otherwise `nil`

### updateMarker(_:)

```swift
func updateMarker(_ marker: any UniversalMapMarkerProtocol)
```

Updates an existing marker's properties.

### removeMarker(withId:)

```swift
func removeMarker(withId id: String)
```

Removes a marker from the map.

**Parameters:**
- `id`: The unique identifier of the marker to remove

### clearAllMarkers()

```swift
func clearAllMarkers()
```

Removes all markers from the map.

## Polyline Management

### addPolyline(_:animated:)

```swift
func addPolyline(_ polyline: UniversalMapPolyline, animated: Bool)
```

Adds a polyline to the map.

**Parameters:**
- `polyline`: The polyline to add
- `animated`: Whether to animate the drawing of the polyline

### updatePolyline(_:animated:)

```swift
func updatePolyline(_ polyline: UniversalMapPolyline, animated: Bool)
```

Updates an existing polyline.

**Parameters:**
- `polyline`: The updated polyline
- `animated`: Whether to animate the update

### updatePolyline(id:coordinates:animated:)

```swift
func updatePolyline(id: String, coordinates: [CLLocationCoordinate2D], animated: Bool)
```

Updates a polyline's coordinates by its ID.

**Parameters:**
- `id`: The polyline's unique identifier
- `coordinates`: The new array of coordinates
- `animated`: Whether to animate the update

### removePolyline(withId:)

```swift
func removePolyline(withId id: String)
```

Removes a polyline from the map.

### clearAllPolylines()

```swift
func clearAllPolylines()
```

Removes all polylines from the map.

## Map Configuration

### setEdgeInsets(_:)

```swift
func setEdgeInsets(_ insets: UniversalMapEdgeInsets)
```

Sets the map's edge insets (padding).

**Parameters:**
- `insets`: The edge insets configuration

### set(preferredRefreshRate:)

```swift
func set(preferredRefreshRate: MapRefreshRate)
```

Sets the preferred refresh rate for map rendering.

**Parameters:**
- `preferredRefreshRate`: The desired refresh rate

### setConfig(_:)

```swift
@MainActor
func setConfig(_ config: any UniversalMapConfigProtocol)
```

Sets the map configuration.

**Parameters:**
- `config`: The configuration object

### set(disabled:)

```swift
@MainActor
func set(disabled: Bool)
```

Enables or disables user interaction with the map.

**Parameters:**
- `disabled`: `true` to disable interaction, `false` to enable

## Styling

### setMapStyle(_:scheme:)

```swift
func setMapStyle(_ style: (any UniversalMapStyleProtocol)?, scheme: ColorScheme)
```

Sets the map style for a specific color scheme.

**Parameters:**
- `style`: The style to apply (or `nil` for default)
- `scheme`: The color scheme (`.light` or `.dark`)

### showBuildings(_:)

```swift
func showBuildings(_ show: Bool)
```

Shows or hides 3D buildings on the map.

### setMaxMinZoomLevels(min:max:)

```swift
func setMaxMinZoomLevels(min: Double, max: Double)
```

Sets the minimum and maximum zoom levels allowed.

**Parameters:**
- `min`: Minimum zoom level (default: 4)
- `max`: Maximum zoom level (default: 18)

## User Location

### showUserLocation(_:)

```swift
func showUserLocation(_ show: Bool)
```

Shows or hides the user's location on the map.

### setUserTrackingMode(_:)

```swift
func setUserTrackingMode(_ tracking: Bool)
```

Enables or disables user tracking mode.

**Parameters:**
- `tracking`: `true` to follow the user's location, `false` to disable

### setUserLocationIcon(_:scale:)

```swift
func setUserLocationIcon(_ image: UIImage, scale: CGFloat)
```

Sets a custom icon for the user's location marker.

**Parameters:**
- `image`: The custom icon image
- `scale`: The scale factor for the icon (default: 1.0)

**Note:** Default implementation does nothing. Override in conforming types.

### updateUserLocation(_:)

```swift
func updateUserLocation(_ location: CLLocation)
```

Manually updates the user's location.

**Parameters:**
- `location`: The new location

**Note:** Default implementation does nothing. Override in conforming types.

### showUserLocationAccuracy(_:)

```swift
func showUserLocationAccuracy(_ show: Bool)
```

Shows or hides the accuracy circle around the user's location.

**Parameters:**
- `show`: `true` to show accuracy circle, `false` to hide

**Note:** Default implementation does nothing. Override in conforming types.

## Interaction

### setInteractionDelegate(_:)

```swift
func setInteractionDelegate(_ delegate: MapInteractionDelegate?)
```

Sets the delegate for receiving map interaction events.

**Parameters:**
- `delegate`: The delegate object (or `nil` to remove)

## View Creation

### makeMapView()

```swift
func makeMapView() -> AnyView
```

Creates the SwiftUI view for this map provider.

**Returns:** A SwiftUI `AnyView` containing the map

## Utility Methods

### zoomOut(minLevel:shift:)

```swift
@MainActor
func zoomOut(minLevel: Float, shift: Double)
```

Zooms out the map by a specified amount.

**Parameters:**
- `minLevel`: The minimum zoom level to reach (default: 10)
- `shift`: The amount to zoom out (default: 0.5)

## Implementing MapProviderProtocol

When creating a custom map provider, you must implement all required methods. Here's a skeleton:

```swift
public class CustomMapProvider: NSObject, MapProviderProtocol {
    private var mapView: CustomMapView?
    
    public var currentLocation: CLLocation? {
        mapView?.userLocation
    }
    
    public var markers: [String: any UniversalMapMarkerProtocol] = [:]
    public var polylines: [String: UniversalMapPolyline] = [:]
    
    required public override init() {
        super.init()
        // Initialize your map
    }
    
    public func updateCamera(to camera: UniversalMapCamera) {
        // Implement camera update
    }
    
    public func addMarker(_ marker: any UniversalMapMarkerProtocol) {
        // Add marker to your map
        markers[marker.id] = marker
    }
    
    // ... implement all other required methods
    
    public func makeMapView() -> AnyView {
        AnyView(CustomMapSwiftUIView(provider: self))
    }
}
```

## Protocol Extensions

The protocol includes default implementations for convenience methods:

```swift
public extension MapProviderProtocol {
    func focusOn(coordinates: [CLLocationCoordinate2D], padding: CGFloat, animated: Bool) {
        // Converts uniform padding to edge insets
    }
    
    func focusOnPolyline(id: String, padding: UIEdgeInsets) {
        // Non-animated version
    }
    
    func focusOnPolyline(id: String) {
        // Zero-padding version
    }
    
    func setUserLocationIcon(_ image: UIImage, scale: CGFloat) {}
    func updateUserLocation(_ location: CLLocation) {}
    func showUserLocationAccuracy(_ show: Bool) {}
}
```

## Conforming Types

IMap provides two built-in conforming types:

- **[GoogleMapsProvider](GoogleMapsProvider.md)** - Google Maps implementation
- **[MapLibreProvider](MapLibreProvider.md)** - MapLibre implementation

## Thread Safety

Many methods are marked with `@MainActor` and must be called on the main thread. Always check the method signature before calling.

## See Also

- [MapProviderFactory](MapProviderFactory.md)
- [GoogleMapsProvider](GoogleMapsProvider.md)
- [MapLibreProvider](MapLibreProvider.md)
- [UniversalMapViewModel](docsUniversalMapViewModel.md)
