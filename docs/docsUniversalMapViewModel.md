# UniversalMapViewModel

`UniversalMapViewModel` is the central view model class that manages map state, interactions, and provides a unified interface for controlling map behavior regardless of the underlying provider (Google Maps or MapLibre).

## Overview

This is the primary class your application will interact with when using IMap. It provides a high-level API for:
- Managing map providers
- Controlling camera position
- Adding/removing markers and polylines
- Handling user location
- Responding to map interactions

## Class Declaration

```swift
public class UniversalMapViewModel: ObservableObject
```

## Properties

### Published Properties

```swift
@Published public var mapProvider: MapProvider
```
The current map provider (`.google` or `.mapLibre`).

```swift
@Published public var camera: UniversalMapCamera?
```
The current camera position and configuration.

```swift
@Published public var showUserLocation: Bool
```
Whether to show the user's location on the map. Default: `true`.

```swift
@Published public var userTrackingMode: Bool
```
Whether to follow the user's location. Default: `false`.

```swift
@Published public var edgeInsets: UniversalMapEdgeInsets
```
The edge insets for the map viewport.

```swift
@Published public var addressInfo: AddressInfo?
```
Information about the selected address (optional).

### Read-Only Properties

```swift
public private(set) var hasAddressPicker: Bool
```
Whether the address picker is enabled.

```swift
public private(set) var hasAddressView: Bool
```
Whether the address view is enabled.

```swift
public private(set) var defaultZoomLevel: Double
```
The default zoom level. Default: `17`.

```swift
public private(set) var config: any MapConfigProtocol
```
The current map configuration.

```swift
public private(set) weak var delegate: UniversalMapViewModelDelegate?
```
The delegate for map interaction events.

```swift
public private(set) var mapProviderInstance: MapProviderProtocol
```
The underlying map provider instance.

## Initialization

```swift
public init(mapProvider: MapProvider, config: any MapConfigProtocol)
```

Creates a new map view model.

**Parameters:**
- `mapProvider`: The initial map provider (`.google` or `.mapLibre`)
- `config`: Configuration object conforming to `MapConfigProtocol`

**Example:**

```swift
let config = MapConfig(
    config: YourMapConfig(
        lightStyle: "https://...",
        darkStyle: "https://..."
    )
)

let viewModel = UniversalMapViewModel(
    mapProvider: .google,
    config: config
)
```

## Map Provider Management

### setMapProvider(_:config:)

```swift
public func setMapProvider(_ provider: MapProvider, config: (any MapConfigProtocol)?)
```

Switches to a different map provider.

**Parameters:**
- `provider`: The new map provider
- `config`: Optional new configuration

**Example:**

```swift
// Switch from Google Maps to MapLibre
viewModel.setMapProvider(.mapLibre, config: nil)
```

### set(config:)

```swift
public func set(config: any MapConfigProtocol)
```

Updates the map configuration.

## Camera Control

### updateCamera(to:)

```swift
public func updateCamera(to camera: UniversalMapCamera)
```

Updates the camera to a new position.

**Example:**

```swift
let camera = UniversalMapCamera(
    center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    zoom: 15,
    bearing: 0,
    pitch: 0,
    animate: true
)

viewModel.updateCamera(to: camera)
```

### focusMap(on:zoom:animated:)

```swift
@MainActor
public func focusMap(on coordinate: CLLocationCoordinate2D, zoom: Double? = nil, animated: Bool = true)
```

Focuses the map on a specific coordinate.

**Parameters:**
- `coordinate`: The target coordinate
- `zoom`: Optional zoom level (defaults to `defaultZoomLevel`)
- `animated`: Whether to animate the camera movement

**Example:**

```swift
await viewModel.focusMap(
    on: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    zoom: 16,
    animated: true
)
```

### focusOnPolyline(id:padding:animated:)

```swift
@MainActor
public func focusOnPolyline(id: String, padding: UIEdgeInsets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: Bool = true)
```

Focuses the map to show an entire polyline.

### focusTo(coordinates:padding:animated:)

```swift
@MainActor
public func focusTo(coordinates: [CLLocationCoordinate2D], padding: CGFloat = 0, animated: Bool)
```

Focuses the map to show multiple coordinates.

### focusToCurrentLocation(animated:)

```swift
@MainActor
public func focusToCurrentLocation(animated: Bool = true)
```

Focuses the map on the user's current location.

## Marker Management

### addMarker(_:)

```swift
@discardableResult
public func addMarker(_ marker: any UniversalMapMarkerProtocol) -> String
```

Adds a marker to the map.

**Returns:** The marker's ID

**Example:**

```swift
let markerView = UIImageView(image: UIImage(systemName: "mappin"))
markerView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)

let marker = UniversalMarker(
    id: "marker-1",
    coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    view: markerView
)

let markerId = viewModel.addMarker(marker)
```

### updateMarker(_:)

```swift
public func updateMarker(_ marker: any UniversalMapMarkerProtocol)
```

Updates an existing marker's position or appearance.

### removeMarker(withId:)

```swift
public func removeMarker(withId id: String)
```

Removes a marker from the map.

### clearAllMarkers()

```swift
public func clearAllMarkers()
```

Removes all markers from the map.

### marker(byId:)

```swift
public func marker(byId id: String) -> (any UniversalMapMarkerProtocol)?
```

Retrieves a marker by its ID.

## Polyline Management

### addPolyline(_:animated:)

```swift
@discardableResult
public func addPolyline(_ polyline: UniversalMapPolyline, animated: Bool = false) -> String
```

Adds a polyline to the map.

**Parameters:**
- `polyline`: The polyline to add
- `animated`: Whether to animate the drawing of the polyline

**Returns:** The polyline's ID

**Example:**

```swift
let coordinates = [
    CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4294)
]

let polyline = UniversalMapPolyline(
    id: "route-1",
    coordinates: coordinates,
    color: .blue,
    width: 5.0,
    geodesic: true
)

viewModel.addPolyline(polyline, animated: true)
```

### updatePolyline(_:animated:)

```swift
public func updatePolyline(_ polyline: UniversalMapPolyline, animated: Bool = false)
```

Updates an existing polyline or adds it if it doesn't exist.

### updatePolyline(id:coordinates:animated:)

```swift
public func updatePolyline(id: String, coordinates: [CLLocationCoordinate2D], animated: Bool = false)
```

Updates a polyline's coordinates by ID.

### removePolyline(withId:)

```swift
public func removePolyline(withId id: String)
```

Removes a polyline from the map.

### clearAllPolylines()

```swift
public func clearAllPolylines()
```

Removes all polylines from the map.

### set(polylines:animated:)

```swift
@MainActor
public func set(polylines: [UniversalMapPolyline], animated: Bool = false)
```

Sets multiple polylines at once.

### setOrUpdate(polylines:animated:)

```swift
@MainActor
public func setOrUpdate(polylines: [UniversalMapPolyline], animated: Bool = false)
```

Sets multiple polylines, removing any that aren't in the new array.

## User Location

### showUserLocation(_:)

```swift
public func showUserLocation(_ show: Bool)
```

Shows or hides the user's location on the map.

### setUserTrackingMode(_:)

```swift
public func setUserTrackingMode(_ tracking: Bool)
```

Enables or disables user tracking mode (camera follows user).

### set(userLocationIcon:scale:)

```swift
@MainActor
public func set(userLocationIcon: UIImage, scale: CGFloat = 1.0)
```

Sets a custom icon for the user's location.

**Example:**

```swift
let icon = UIImage(systemName: "location.circle.fill")!
await viewModel.set(userLocationIcon: icon, scale: 1.2)
```

### showUserLocationAccuracy(_:)

```swift
@MainActor
public func showUserLocationAccuracy(_ show: Bool)
```

Shows or hides the accuracy circle around the user's location.

## Map Styling

### setMapStyle(_:scheme:)

```swift
public func setMapStyle(_ style: any UniversalMapStyleProtocol, scheme: ColorScheme)
```

Sets the map style for a specific color scheme.

**Example:**

```swift
viewModel.setMapStyle(GoogleLightMapStyle(), scheme: .light)
viewModel.setMapStyle(GoogleDarkMapStyle(), scheme: .dark)
```

### showBuildings(_:)

```swift
public func showBuildings(_ show: Bool)
```

Shows or hides 3D buildings on the map.

## Map Configuration

### setEdgeInsets(_:)

```swift
public func setEdgeInsets(_ insets: UniversalMapEdgeInsets)
```

Sets the edge insets for the map viewport.

**Example:**

```swift
let insets = UniversalMapEdgeInsets(
    top: 100,
    left: 0,
    bottom: 200,
    right: 0,
    animated: true
)

viewModel.setEdgeInsets(insets)
```

### set(preferredRefreshRate:)

```swift
@MainActor
public func set(preferredRefreshRate: MapRefreshRate)
```

Sets the preferred refresh rate for map rendering.

### set(disabled:)

```swift
@MainActor
public func set(disabled: Bool)
```

Enables or disables user interaction with the map.

### zoomOut(minLevel:shift:)

```swift
@MainActor
public func zoomOut(minLevel: Float = 10, shift: Double = 0.5)
```

Zooms out the map by a specified amount.

## Delegation

### setInteractionDelegate(_:)

```swift
public func setInteractionDelegate(_ delegate: any UniversalMapViewModelDelegate)
```

Sets the delegate for receiving map interaction events.

**Example:**

```swift
class MyMapController: UniversalMapViewModelDelegate {
    func mapDidTapMarker(map: MapProviderProtocol, id: String) -> Bool {
        print("Marker tapped: \(id)")
        return true
    }
    
    func mapDidEndDragging(map: MapProviderProtocol, at location: CLLocation) {
        print("Map dragged to: \(location.coordinate)")
    }
}

let controller = MyMapController()
viewModel.setInteractionDelegate(controller)
```

## Creating Views

### makeMapView()

```swift
public func makeMapView() -> AnyView
```

Creates the SwiftUI view for the map.

**Example:**

```swift
struct ContentView: View {
    @StateObject var viewModel: UniversalMapViewModel
    
    var body: some View {
        VStack {
            viewModel.makeMapView()
                .frame(height: 400)
            
            Button("Add Marker") {
                // Add marker logic
            }
        }
    }
}
```

## Route Tracking

### startTracking(route:)

```swift
public func startTracking(route: UniversalMapPolyline)
```

Starts tracking movement along a route.

**Example:**

```swift
let route = UniversalMapPolyline(coordinates: routeCoordinates)
viewModel.startTracking(route: route)
```

## Address Management

### set(hasAddressPicker:)

```swift
public func set(hasAddressPicker: Bool)
```

Enables or disables the address picker feature.

### set(hasAddressView:)

```swift
public func set(hasAddressView: Bool)
```

Enables or disables the address view feature.

### set(addressViewInfo:)

```swift
@MainActor
public func set(addressViewInfo: AddressInfo?)
```

Sets the address information to display.

## Best Practices

1. **Use @StateObject or @ObservedObject** - Since `UniversalMapViewModel` conforms to `ObservableObject`, use appropriate property wrappers in SwiftUI views.

2. **Main Actor Operations** - Many methods are marked with `@MainActor`. Ensure you call them from the main thread or use `await`.

3. **Memory Management** - The view model automatically cleans up resources in its `deinit`. Don't create retain cycles when setting delegates.

4. **Provider Switching** - When switching providers, all markers and polylines are automatically transferred to the new provider.

5. **Marker IDs** - Always use unique IDs for markers to avoid conflicts.

## See Also

- [UniversalMapViewModelDelegate](UniversalMapViewModelDelegate.md)
- [MapProviderProtocol](MapProviderProtocol.md)
- [UniversalMapMarker](UniversalMapMarker.md)
- [UniversalMapPolyline](UniversalMapPolyline.md)
