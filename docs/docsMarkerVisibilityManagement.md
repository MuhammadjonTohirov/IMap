# Marker Visibility Management

IMap includes intelligent marker visibility management to optimize performance when displaying large numbers of markers.

## Overview

When working with hundreds or thousands of markers, rendering all of them simultaneously can cause performance issues. IMap's visibility management system:

- **Culls off-screen markers** - Only renders markers in the visible viewport
- **Maintains marker state** - Keeps all markers in memory for quick access
- **Automatically updates** - Refreshes visibility when the camera moves
- **Optimizes rendering** - Reduces draw calls and memory usage

## How It Works

### Two-Tier Storage System

IMap (specifically the Google Maps provider) uses a two-tier storage system:

```swift
// All markers ever added (data source)
public private(set) var allMarkers: [String: UniversalMarker] = [:]

// Currently rendered markers (visible on map)
public private(set) var markers: [String: UniversalMarker] = [:]
```

### Visibility Algorithm

1. **Camera Change**: User pans, zooms, or camera is updated programmatically
2. **Calculate Bounds**: Determine the visible map region
3. **Check Markers**: For each marker in `allMarkers`, check if it's within bounds
4. **Diff Calculation**: Determine which markers to add/remove
5. **Update Map**: Add newly visible markers, remove off-screen markers

### Performance Benefits

With 10,000 markers:
- **Without culling**: 10,000 markers rendered, ~30 FPS
- **With culling**: ~50-200 markers rendered (depending on zoom), 60 FPS

## Implementation Details

### Visibility Refresh (Google Maps)

```swift
func refreshVisibleMarkers() {
    guard let mapView = mapView else { return }
    
    // Get visible region bounds
    let region = mapView.projection.visibleRegion()
    let bounds = GMSCoordinateBounds(coordinate: region.nearLeft, coordinate: region.farRight)
        .includingCoordinate(region.nearRight)
        .includingCoordinate(region.farLeft)
    
    // Determine visible marker IDs
    let visibleIds: Set<String> = Set(
        allMarkers
            .lazy
            .filter { bounds.contains($0.value.position) }
            .map { $0.key }
    )
    
    // Currently rendered IDs
    let renderedIds = Set(markers.keys)
    
    // Calculate diff
    let toAdd = visibleIds.subtracting(renderedIds)
    let toRemove = renderedIds.subtracting(visibleIds)
    
    // Remove off-screen markers
    for id in toRemove {
        if let marker = markers[id] {
            marker.map = nil
            markers[id] = nil
        }
    }
    
    // Add newly visible markers
    for id in toAdd {
        if let marker = allMarkers[id] {
            marker.map = mapView
            markers[id] = marker
        }
    }
}
```

### Automatic Refresh Triggers

Visibility is automatically refreshed on:

- **Camera idle** - After panning/zooming completes
- **Camera position change** - During continuous movement (for smooth transitions)
- **Marker addition** - When new markers are added
- **Marker update** - When marker positions change
- **Focus operations** - When focusing on coordinates or polylines

## Usage Patterns

### Adding Many Markers

```swift
func addThousandsOfMarkers(locations: [Location]) {
    for location in locations {
        let marker = UniversalMarker(
            id: "loc-\(location.id)",
            coordinate: location.coordinate,
            view: createMarkerView(for: location)
        )
        
        // Markers are added to data source
        viewModel.addMarker(marker)
        // Only visible markers are rendered
    }
}
```

### Updating Marker Positions

```swift
func updateVehiclePositions(vehicles: [Vehicle]) {
    for vehicle in vehicles {
        guard let marker = viewModel.marker(byId: "vehicle-\(vehicle.id)") as? UniversalMarker else {
            continue
        }
        
        marker.set(coordinate: vehicle.location)
        marker.set(heading: vehicle.heading)
        
        viewModel.updateMarker(marker)
        // Visibility automatically recalculated
    }
}
```

### Bulk Marker Management

```swift
class MarkerManager {
    private let viewModel: UniversalMapViewModel
    
    func updateMarkers(newLocations: [Location]) {
        // Create marker lookup
        let newMarkerIds = Set(newLocations.map { "loc-\($0.id)" })
        
        // Get existing IDs from view model
        let existingIds = Set(viewModel.mapProviderInstance.markers.keys)
        
        // Remove markers that are no longer needed
        let toRemove = existingIds.subtracting(newMarkerIds)
        toRemove.forEach { viewModel.removeMarker(withId: $0) }
        
        // Add or update markers
        for location in newLocations {
            let id = "loc-\(location.id)"
            
            if existingIds.contains(id) {
                // Update existing
                if let marker = viewModel.marker(byId: id) as? UniversalMarker {
                    marker.set(coordinate: location.coordinate)
                    viewModel.updateMarker(marker)
                }
            } else {
                // Add new
                let marker = createMarker(for: location)
                viewModel.addMarker(marker)
            }
        }
    }
}
```

## Performance Optimization Strategies

### 1. Simplify Marker Views

For large datasets, use simple marker views:

```swift
func createSimpleMarker(id: String, coordinate: CLLocationCoordinate2D) -> UniversalMarker {
    // Simple colored circle
    let view = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 12))
    view.backgroundColor = .systemBlue
    view.layer.cornerRadius = 6
    
    return UniversalMarker(id: id, coordinate: coordinate, view: view)
}
```

### 2. Use Clustering

Group nearby markers at lower zoom levels:

```swift
func addMarkersWithClustering(locations: [Location], zoom: Float) {
    if zoom < 12 {
        // Create cluster markers
        let clusters = createClusters(locations: locations, zoom: zoom)
        clusters.forEach { cluster in
            let marker = createClusterMarker(count: cluster.count, coordinate: cluster.center)
            viewModel.addMarker(marker)
        }
    } else {
        // Show individual markers
        locations.forEach { location in
            let marker = createMarker(for: location)
            viewModel.addMarker(marker)
        }
    }
}
```

### 3. Lazy Loading

Load markers progressively as user explores:

```swift
class LazyMarkerLoader {
    private let viewModel: UniversalMapViewModel
    private var loadedRegions: Set<String> = []
    
    func loadMarkersForVisibleRegion(bounds: GMSCoordinateBounds) {
        let regionKey = regionKey(for: bounds)
        
        guard !loadedRegions.contains(regionKey) else { return }
        
        Task {
            let markers = await fetchMarkersForRegion(bounds: bounds)
            
            await MainActor.run {
                markers.forEach { viewModel.addMarker($0) }
                loadedRegions.insert(regionKey)
            }
        }
    }
    
    private func regionKey(for bounds: GMSCoordinateBounds) -> String {
        // Create unique key for region
        "\(bounds.northEast.latitude)-\(bounds.northEast.longitude)"
    }
}
```

### 4. Debounce Updates

Prevent excessive updates during rapid camera changes:

```swift
class DebouncedMarkerUpdater {
    private var updateTask: Task<Void, Never>?
    
    func scheduleUpdate(markers: [UniversalMarker]) {
        // Cancel previous task
        updateTask?.cancel()
        
        // Schedule new update
        updateTask = Task {
            // Wait for camera to settle
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                markers.forEach { viewModel.updateMarker($0) }
            }
        }
    }
}
```

### 5. Marker Recycling

Reuse marker objects instead of creating new ones:

```swift
class MarkerPool {
    private var availableMarkers: [UniversalMarker] = []
    private var activeMarkers: [String: UniversalMarker] = [:]
    
    func getMarker(for location: Location) -> UniversalMarker {
        let id = "loc-\(location.id)"
        
        if let existing = activeMarkers[id] {
            return existing
        }
        
        let marker: UniversalMarker
        if let recycled = availableMarkers.popLast() {
            // Reuse existing marker
            marker = recycled
            marker.set(coordinate: location.coordinate)
        } else {
            // Create new marker
            marker = createMarker(for: location)
        }
        
        activeMarkers[id] = marker
        return marker
    }
    
    func recycleMarker(id: String) {
        if let marker = activeMarkers.removeValue(forKey: id) {
            availableMarkers.append(marker)
        }
    }
}
```

## Monitoring Performance

### Tracking Rendered Markers

```swift
extension UniversalMapViewModel {
    var renderedMarkerCount: Int {
        mapProviderInstance.markers.count
    }
    
    var totalMarkerCount: Int {
        // Access internal storage if available
        // For Google Maps provider:
        if let googleProvider = mapProviderInstance as? GoogleMapsProvider {
            // Would need to expose allMarkers count
        }
        return mapProviderInstance.markers.count
    }
}
```

### Debug Overlay

```swift
struct MapWithDebugInfo: View {
    @ObservedObject var viewModel: UniversalMapViewModel
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            viewModel.makeMapView()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Rendered: \(viewModel.renderedMarkerCount)")
                Text("Total: \(viewModel.totalMarkerCount)")
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
            .padding()
        }
    }
}
```

## Platform Differences

### Google Maps

- ✅ **Full visibility culling implemented**
- ✅ **Automatic refresh on camera changes**
- ✅ **Efficient diff-based updates**

### MapLibre

- ⚠️ **Basic implementation**
- ⚠️ **All markers typically rendered**
- 💡 **Consider manual clustering for large datasets**

## Best Practices

1. **Add All Markers Upfront**: Let the system handle visibility
   ```swift
   // Good: Add all markers
   allLocations.forEach { viewModel.addMarker(createMarker($0)) }
   ```

2. **Trust the System**: Don't manually show/hide markers based on zoom
   ```swift
   // Avoid: Manual visibility management
   // Let IMap handle it automatically
   ```

3. **Use Consistent IDs**: Helps with updates and prevents duplicates
   ```swift
   let marker = UniversalMarker(id: "vehicle-\(vehicle.id)", ...)
   ```

4. **Monitor Performance**: Track rendered vs total markers
   ```swift
   print("Rendering \(rendered) of \(total) markers")
   ```

5. **Progressive Enhancement**: Start simple, add complexity if needed
   ```swift
   // Start with: Simple marker addition
   // Add if needed: Clustering
   // Add if needed: Lazy loading
   ```

## Troubleshooting

### All Markers Rendering

If all markers are rendering despite culling:

1. Check if using Google Maps provider (MapLibre may not have culling)
2. Verify markers have valid coordinates
3. Ensure `refreshVisibleMarkers()` is being called

### Markers Disappearing

If markers disappear unexpectedly:

1. Check marker IDs are unique
2. Verify coordinates are within valid ranges
3. Check if markers are being accidentally removed

### Performance Issues

If experiencing lag with markers:

1. Reduce marker view complexity
2. Implement clustering for high-density areas
3. Use lazy loading for very large datasets
4. Profile rendering time per marker

## See Also

- [UniversalMapMarker](docsUniversalMapMarker.md)
- [UniversalMapViewModel](docsUniversalMapViewModel.md)
- [GoogleMapsProvider](GoogleMapsProvider.md)
- [Performance Guide](PerformanceGuide.md)
