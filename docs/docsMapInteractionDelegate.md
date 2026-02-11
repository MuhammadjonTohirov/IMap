# MapInteractionDelegate

`MapInteractionDelegate` is a protocol that allows you to respond to user interactions with the map, such as taps, drags, and camera movements.

## Overview

This delegate protocol provides callbacks for all major map interaction events, enabling you to:
- Respond to map taps and marker selections
- Track map movement and dragging
- Know when the map has finished loading
- Update UI based on camera position changes

## Protocol Declaration

```swift
public protocol MapInteractionDelegate: AnyObject
```

## Methods

### mapDidStartDragging()

```swift
func mapDidStartDragging()
```

Called when the user starts dragging the map with their finger.

**Use Cases:**
- Hide floating UI elements
- Pause animations
- Clear temporary selections

**Example:**

```swift
func mapDidStartDragging() {
    // Hide address picker while user is dragging
    showAddressPicker = false
}
```

### mapDidStartMoving()

```swift
func mapDidStartMoving()
```

Called when the map starts moving, either from user interaction or programmatic changes.

**Difference from `mapDidStartDragging()`:**
- `mapDidStartDragging()`: Only user gestures
- `mapDidStartMoving()`: Both user and programmatic movement

**Example:**

```swift
func mapDidStartMoving() {
    // Update loading indicator
    isMapMoving = true
}
```

### mapDidEndDragging(at:)

```swift
func mapDidEndDragging(at location: CLLocation)
```

Called when the map stops being dragged and becomes idle.

**Parameters:**
- `location`: The final location of the map center

**Use Cases:**
- Fetch nearby places
- Update address information
- Save new map position
- Re-show hidden UI elements

**Example:**

```swift
func mapDidEndDragging(at location: CLLocation) {
    // Fetch address for the new center location
    Task {
        let address = await reverseGeocode(location.coordinate)
        viewModel.set(addressViewInfo: AddressInfo(
            name: address,
            location: location.coordinate
        ))
    }
}
```

### mapDidTapMarker(id:)

```swift
func mapDidTapMarker(id: String) -> Bool
```

Called when a marker is tapped.

**Parameters:**
- `id`: The unique identifier of the tapped marker

**Returns:** 
- `true` to prevent the default behavior (showing info window)
- `false` to allow default behavior

**Example:**

```swift
func mapDidTapMarker(id: String) -> Bool {
    // Show custom detail view for this marker
    selectedMarkerId = id
    showMarkerDetail = true
    
    // Prevent default info window
    return true
}
```

### mapDidTap(at:)

```swift
func mapDidTap(at coordinate: CLLocationCoordinate2D)
```

Called when the map is tapped (not on a marker).

**Parameters:**
- `coordinate`: The coordinate where the tap occurred

**Use Cases:**
- Add new markers at tap location
- Clear marker selection
- Show location details
- Create waypoints

**Example:**

```swift
func mapDidTap(at coordinate: CLLocationCoordinate2D) {
    // Clear marker selection
    selectedMarkerId = nil
    
    // Or add a new marker at tap location
    let marker = UniversalMarker(
        coordinate: coordinate,
        view: createMarkerView()
    )
    viewModel.addMarker(marker)
}
```

### mapDidLoaded()

```swift
func mapDidLoaded()
```

Called when the map has finished initial loading and rendering.

**Use Cases:**
- Hide loading indicators
- Trigger initial animations
- Load map data
- Set initial camera position

**Example:**

```swift
func mapDidLoaded() {
    // Hide loading screen
    isLoading = false
    
    // Load markers
    loadMarkers()
    
    // Animate to user location
    Task {
        await viewModel.focusToCurrentLocation(animated: true)
    }
}
```

## Default Implementations

The protocol provides default empty implementations for all methods, so you only need to implement the ones you need:

```swift
public extension MapInteractionDelegate {
    func mapDidStartDragging() {}
    func mapDidStartMoving() {}
    func mapDidEndDragging(at location: CLLocation) {}
    func mapDidTapMarker(id: String) -> Bool { false }
    func mapDidTap(at coordinate: CLLocationCoordinate2D) {}
    func mapDidLoaded() {}
}
```

## Usage Examples

### Basic Implementation

```swift
class MapViewController: UIViewController, MapInteractionDelegate {
    private var viewModel: UniversalMapViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = UniversalMapViewModel(mapProvider: .google, config: config)
        viewModel.setInteractionDelegate(self)
    }
    
    // Implement only the methods you need
    func mapDidTapMarker(id: String) -> Bool {
        print("Marker tapped: \(id)")
        showDetailsFor(markerId: id)
        return true
    }
}
```

### SwiftUI Integration

```swift
class MapCoordinator: ObservableObject, MapInteractionDelegate {
    @Published var selectedLocation: CLLocationCoordinate2D?
    @Published var selectedMarkerId: String?
    @Published var isMapReady = false
    
    let viewModel: UniversalMapViewModel
    
    init() {
        let config = MapConfig(config: MyMapConfig())
        viewModel = UniversalMapViewModel(mapProvider: .google, config: config)
        viewModel.setInteractionDelegate(self)
    }
    
    func mapDidLoaded() {
        isMapReady = true
    }
    
    func mapDidTapMarker(id: String) -> Bool {
        selectedMarkerId = id
        return true
    }
    
    func mapDidTap(at coordinate: CLLocationCoordinate2D) {
        selectedLocation = coordinate
        selectedMarkerId = nil
    }
    
    func mapDidEndDragging(at location: CLLocation) {
        selectedLocation = location.coordinate
    }
}

struct ContentView: View {
    @StateObject private var coordinator = MapCoordinator()
    
    var body: some View {
        ZStack {
            coordinator.viewModel.makeMapView()
            
            if !coordinator.isMapReady {
                ProgressView("Loading map...")
            }
            
            if let location = coordinator.selectedLocation {
                LocationDetailView(location: location)
            }
        }
    }
}
```

### Address Picker Implementation

```swift
class AddressPickerDelegate: MapInteractionDelegate {
    private weak var viewModel: UniversalMapViewModel?
    private let geocoder = CLGeocoder()
    
    func mapDidStartDragging() {
        // Clear current address while dragging
        viewModel?.set(addressViewInfo: nil)
    }
    
    func mapDidEndDragging(at location: CLLocation) {
        // Fetch new address
        fetchAddress(for: location)
    }
    
    private func fetchAddress(for location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let placemark = placemarks?.first,
                  let address = placemark.name else { return }
            
            let addressInfo = AddressInfo(
                name: address,
                location: location.coordinate
            )
            
            Task { @MainActor in
                self?.viewModel?.set(addressViewInfo: addressInfo)
            }
        }
    }
}
```

### Marker Selection Manager

```swift
class MarkerSelectionManager: MapInteractionDelegate {
    @Published var selectedMarker: MarkerData?
    private let viewModel: UniversalMapViewModel
    private var markers: [String: MarkerData] = [:]
    
    init(viewModel: UniversalMapViewModel) {
        self.viewModel = viewModel
        viewModel.setInteractionDelegate(self)
    }
    
    func mapDidTapMarker(id: String) -> Bool {
        selectedMarker = markers[id]
        
        // Highlight selected marker
        if let marker = viewModel.marker(byId: id) {
            highlightMarker(marker)
        }
        
        // Focus camera on marker
        if let coordinate = selectedMarker?.coordinate {
            Task {
                await viewModel.focusMap(on: coordinate, zoom: 16, animated: true)
            }
        }
        
        return true
    }
    
    func mapDidTap(at coordinate: CLLocationCoordinate2D) {
        // Deselect marker when tapping map
        selectedMarker = nil
        clearMarkerHighlights()
    }
    
    private func highlightMarker(_ marker: any UniversalMapMarkerProtocol) {
        // Implementation to highlight marker
    }
    
    private func clearMarkerHighlights() {
        // Implementation to clear highlights
    }
}
```

### Navigation Delegate

```swift
class NavigationDelegate: MapInteractionDelegate {
    private var isNavigating = false
    private var waypoints: [CLLocationCoordinate2D] = []
    
    func mapDidTap(at coordinate: CLLocationCoordinate2D) {
        if isNavigating {
            // Ignore taps during navigation
            return
        }
        
        // Add waypoint
        addWaypoint(coordinate)
    }
    
    func mapDidTapMarker(id: String) -> Bool {
        if isNavigating {
            // During navigation, only show marker info
            showMarkerInfo(id)
            return true
        }
        
        // Normal behavior when not navigating
        return false
    }
    
    func mapDidEndDragging(at location: CLLocation) {
        if isNavigating {
            // Check if user has strayed from route
            checkRouteDeviation(location)
        }
    }
    
    private func addWaypoint(_ coordinate: CLLocationCoordinate2D) {
        waypoints.append(coordinate)
        // Update route visualization
    }
    
    private func checkRouteDeviation(_ location: CLLocation) {
        // Check if off route and trigger recalculation
    }
    
    private func showMarkerInfo(_ id: String) {
        // Show marker details
    }
}
```

### Analytics Tracking

```swift
class MapAnalyticsDelegate: MapInteractionDelegate {
    func mapDidLoaded() {
        Analytics.log(event: "map_loaded")
    }
    
    func mapDidTapMarker(id: String) -> Bool {
        Analytics.log(event: "marker_tapped", parameters: ["marker_id": id])
        return false // Continue with default behavior
    }
    
    func mapDidTap(at coordinate: CLLocationCoordinate2D) {
        Analytics.log(event: "map_tapped", parameters: [
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude
        ])
    }
    
    func mapDidEndDragging(at location: CLLocation) {
        Analytics.log(event: "map_dragged")
    }
}
```

### Multi-Delegate Pattern

If you need multiple objects to respond to map events:

```swift
class MulticastMapDelegate: MapInteractionDelegate {
    private var delegates: [MapInteractionDelegate] = []
    
    func add(delegate: MapInteractionDelegate) {
        delegates.append(delegate)
    }
    
    func mapDidLoaded() {
        delegates.forEach { $0.mapDidLoaded() }
    }
    
    func mapDidTapMarker(id: String) -> Bool {
        // Return true if any delegate returns true
        delegates.reduce(false) { $0 || $1.mapDidTapMarker(id: id) }
    }
    
    func mapDidTap(at coordinate: CLLocationCoordinate2D) {
        delegates.forEach { $0.mapDidTap(at: coordinate) }
    }
    
    func mapDidStartDragging() {
        delegates.forEach { $0.mapDidStartDragging() }
    }
    
    func mapDidStartMoving() {
        delegates.forEach { $0.mapDidStartMoving() }
    }
    
    func mapDidEndDragging(at location: CLLocation) {
        delegates.forEach { $0.mapDidEndDragging(at: location) }
    }
}

// Usage
let multicast = MulticastMapDelegate()
multicast.add(delegate: analyticsDelegate)
multicast.add(delegate: addressPickerDelegate)
multicast.add(delegate: selectionDelegate)

viewModel.setInteractionDelegate(multicast)
```

## Best Practices

1. **Weak References**: Always use `weak var` when storing delegate references to avoid retain cycles

2. **Main Thread**: Delegate methods are called on the main thread, but async operations should still use `Task { @MainActor in ... }`

3. **Performance**: Keep delegate method implementations lightweight. Perform heavy work asynchronously

4. **Return Values**: For `mapDidTapMarker`, return `true` only when you want to completely override default behavior

5. **State Management**: Use delegate callbacks to update your app's state, not to perform map operations directly

## Thread Safety

All delegate methods are called on the main thread, so UI updates are safe:

```swift
func mapDidEndDragging(at location: CLLocation) {
    // Safe to update UI directly
    self.label.text = "Location: \(location.coordinate)"
    
    // But still use Task for async work
    Task {
        let address = await fetchAddress(location)
        self.addressLabel.text = address
    }
}
```

## See Also

- [UniversalMapViewModel](UniversalMapViewModel.md)
- [UniversalMapViewModelDelegate](UniversalMapViewModelDelegate.md)
- [MapProviderProtocol](MapProviderProtocol.md)
