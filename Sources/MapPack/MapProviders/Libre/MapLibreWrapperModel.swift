//
//  MapLibreWrapperModel.swift
//  LibreMap
//
//  Created by Muhammadjon Tohirov on 07/05/25.
//
// MapLibreWrapperModel.swift

import Foundation
import MapLibre
import SwiftUI
import Combine
import UIKit

public protocol LibreMapsKeyProvider: UniversalMapConfigProtocol, AnyObject {
    
}

open class MapLibreWrapperModel: NSObject, ObservableObject {
    // Map view reference
    public private(set) weak var mapView: MLNMapView?
    
    // Published properties
    @Published var isDrawingPolyline: Bool = false
    @Published var drawingCoordinates: [CLLocationCoordinate2D] = []
    @Published var savedPolylines: [MapPolyline] = []
    @Published var userLocation: CLLocation?
    @Published var mapCenter: CLLocationCoordinate2D?
    @Published var zoomLevel: Double = 15
    @Published var isMapLoaded: Bool = false
    @Published var isBuildingsEnabled: Bool = false
    // Map markers
    @Published var markers: [String: UniversalMarker] = [:]
    
    // User Location Customization
    public var userLocationImage: UIImage?
    public var userLocationIconScale: CGFloat = 1.0
    
    public var config: (any UniversalMapConfigProtocol)?
    public private(set) weak var interactionDelegate: MapInteractionDelegate?

    // Style fallback management
    private(set) var hasAttemptedFallback: Bool = false
    let fallbackStyleURL = "https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json"

    // Temporary source and layer IDs
    let tempPolylineSourceID = "temp-polyline-source"
    let tempPolylineLayerID = "temp-polyline-layer"
    
    // User Location Accuracy Layer
    let userAccuracySourceID = "user-accuracy-source"
    let userAccuracyLayerID = "user-accuracy-layer"
    
    // MARK: - Readiness management
    
    private var pendingCameraActions: [() -> Void] = []
    private var boundsCheckCancellable: AnyCancellable?
    
    func set(hasAttemptedFallback: Bool) {
        self.hasAttemptedFallback = hasAttemptedFallback
    }
    
    private var isViewSized: Bool {
        guard let mapView = mapView else { return false }
        return mapView.bounds.width > 0 && mapView.bounds.height > 0
    }
    
    private func enqueueWhenReady(_ action: @escaping () -> Void) {
        if isViewSized && isMapLoaded {
            action()
            return
        }
        pendingCameraActions.append(action)
        scheduleReadinessChecks()
    }
    
    private func scheduleReadinessChecks() {
        DispatchQueue.main.async { [weak self] in
            self?.drainPendingActionsIfReady()
        }
        
        boundsCheckCancellable?.cancel()
        let publisher = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
        boundsCheckCancellable = publisher
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.isViewSized && self.isMapLoaded {
                    self.boundsCheckCancellable?.cancel()
                    self.boundsCheckCancellable = nil
                    self.drainPendingActionsIfReady()
                }
            }
    }
    
    func drainPendingActionsIfReady() {
        guard isViewSized && isMapLoaded else { return }
        let actions = pendingCameraActions
        pendingCameraActions.removeAll()
        actions.forEach { $0() }
    }
    
    func onChangeColorScheme(_ scheme: ColorScheme) {
        switch scheme {
        case .dark:
            self.mapView?.styleURL = .init(string: self.config?.darkStyle ?? "https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json")
        default:
            self.mapView?.styleURL = .init(string: self.config?.lightStyle ?? "https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json")
        }
    }
    
    @MainActor
    func set(config: any UniversalMapConfigProtocol) {
        self.config = config
    }
    
    func set(mapView: MLNMapView?) {
        self.mapView = mapView
        // Attempt to drain if the view is already sized and style may be loaded
        scheduleReadinessChecks()
    }
    
    @MainActor
    func set(preferredRefreshRate: MapRefreshRate) {
        self.mapView?.preferredFramesPerSecond = preferredRefreshRate.libre
    }
    
    // MARK: - Custom Methods
    
    func centerMap(on coordinate: CLLocationCoordinate2D, zoom: Double? = nil, animated: Bool = true) {
        
        let perform = { [weak self] in
            guard let self = self, let mapView = self.mapView else { return }
            let _zoom = (zoom ?? self.zoomLevel) / 1.036
            
            let widthPoints = mapView.bounds.width > 0 ? mapView.bounds.width : UIScreen.main.bounds.width
            
            let acrossDistance = self.metersAcrossAtZoomLevel(
                _zoom,
                latitude: coordinate.latitude,
                screenWidthPoints: widthPoints
            )
            
            let camera = MLNMapCamera(
                lookingAtCenter: coordinate,
                acrossDistance: acrossDistance,
                pitch: 0,
                heading: 0
            )
            mapView.setCamera(camera, animated: animated)
        }
        
        if !isViewSized || !isMapLoaded {
            enqueueWhenReady(perform)
        } else {
            perform()
        }
    }
    
    func flyTo(coordinate: CLLocationCoordinate2D, zoom: Double? = nil, animated: Bool = true) {
        let perform = { [weak self] in
            guard let self = self, let mapView = self.mapView else { return }
            let _zoom = (zoom ?? self.zoomLevel) / 1.036
            
            let widthPoints = mapView.bounds.width > 0 ? mapView.bounds.width : UIScreen.main.bounds.width
            
            let acrossDistance = self.metersAcrossAtZoomLevel(
                _zoom,
                latitude: coordinate.latitude,
                screenWidthPoints: widthPoints
            )
            let camera = MLNMapCamera(lookingAtCenter: coordinate,
                                     acrossDistance: acrossDistance,
                                     pitch: 0,
                                     heading: 0)
            
            if let zoom = zoom {
                mapView.zoomLevel = zoom
            }
            
            mapView.setCamera(camera, animated: animated)
        }
        
        if !isViewSized || !isMapLoaded {
            enqueueWhenReady(perform)
        } else {
            perform()
        }
    }
    
    func set(mapDelegate: MapInteractionDelegate?) {
        self.interactionDelegate = mapDelegate
    }
    
    func toggleBuildings(visible: Bool) {
        self.isBuildingsEnabled = visible
        guard let mapView = mapView, let style = mapView.style else { return }
        let layerId = "3d-buildings"
        
        // If layer exists, just toggle visibility
        if let layer = style.layer(withIdentifier: layerId) {
            layer.isVisible = visible
            return
        }
        
        guard visible else { return }
        
        // Try to find a suitable source
        // We look for a source that likely contains building data (often named 'composite', 'openmaptiles', or just the first vector source)
        var targetSource: MLNSource?
        
        if let source = style.source(withIdentifier: "composite") {
            targetSource = source
        } else if let source = style.source(withIdentifier: "openmaptiles") {
            targetSource = source
        } else {
             // Fallback: find first vector source
            targetSource = style.sources.first { $0 is MLNVectorTileSource }
        }
        
        guard let source = targetSource else { return }
        
        let buildingLayer = MLNFillExtrusionStyleLayer(identifier: layerId, source: source)
        buildingLayer.sourceLayerIdentifier = "building"
        
        // Filter: only extrude actual buildings, and maybe exclude "false" buildings if data requires
        // 'extrude' is often a property in OMT
        buildingLayer.predicate = NSPredicate(format: "extrude == 'true' OR height > 0")
        
        // Styling
        buildingLayer.fillExtrusionColor = NSExpression(forConstantValue: UIColor.lightGray)
        buildingLayer.fillExtrusionOpacity = NSExpression(forConstantValue: 0.6)
        
        // Height
        // If 'height' property exists, use it. Otherwise 0.
        buildingLayer.fillExtrusionHeight = NSExpression(format: "height")
        
        // Min zoom
        buildingLayer.minimumZoomLevel = 15
        
        // Insert below labels if possible
        if let symbolLayer = style.layers.first(where: { $0 is MLNSymbolStyleLayer }) {
            style.insertLayer(buildingLayer, below: symbolLayer)
        } else {
            style.addLayer(buildingLayer)
        }
    }
    
    func zoomOut(minLevel: Float = 10, shift: Double = 0.5) {
        guard let mapView = self.mapView else { return }

        let currentZoom = mapView.zoomLevel
        let targetZoom = Double(minLevel)

        let newZoom = max(currentZoom - shift, targetZoom)

        // Animate to a zoomed-out level
        mapView.setCamera(
            mapView.camera,
            withDuration: 0.2,
            animationTimingFunction: CAMediaTimingFunction(name: .easeInEaseOut)
        )
        mapView.setZoomLevel(newZoom, animated: true)
    }

    func resetStyleFallbackState() {
        hasAttemptedFallback = false
    }
    
    func updateUserLocation(_ location: CLLocation) {
        self.userLocation = location
        
        // Find the user location annotation view and update it
        if let mapView = mapView,
           let userLocationAnnotation = mapView.userLocation,
           let view = mapView.view(for: userLocationAnnotation) as? UniversalUserLocationAnnotationView {
            view.update(accuracy: location.horizontalAccuracy, zoom: mapView.zoomLevel, latitude: location.coordinate.latitude)
        }
    }
}

extension MapLibreWrapperModel {
    // MARK: - Marker Management
    
    func addMarker(_ marker: any UniversalMapMarkerProtocol) {
        guard let marker = marker as? UniversalMarker else { return }
        
        Logging.l("Add marker to map view by id: \(marker.id)")
        markers[marker.id] = marker
        addMarkerToMap(marker)
    }
    
    func removeMarker(withId id: String) {
        guard let mapView = mapView else { return }
        
        if let annotation = mapView.annotations?.first(where: { ($0 as? UniversalMarker)?.id == id }) {
            Logging.l("Remove marker from map view by id: \(id)")
            mapView.removeAnnotation(annotation)
        }
        
        markers.removeValue(forKey: id)
    }
    
    func clearAllMarkers() {
        guard let mapView = mapView else { return }

        mapView.annotations?.forEach { annotation in
            mapView.removeAnnotation(annotation)
        }
        
        markers.removeAll()
    }
    
    func addMarkerToMap(_ marker: UniversalMarker) {
        guard let mapView = mapView else { return }
        mapView.addAnnotation(marker)
        marker.updatePosition(coordinate: marker.coordinate, heading: marker.rotation)
        marker.view?.transform = CGAffineTransform(rotationAngle: (.pi / 180) * CGFloat(marker.rotation))
    }
    
    func focusOn(coordinates: [CLLocationCoordinate2D], edges: UIEdgeInsets, animated: Bool) {
        self.mapView?.setVisibleCoordinates(coordinates, count: UInt(coordinates.count), edgePadding: edges, animated: animated)
    }
}

extension MLNPointAnnotation {
    var identifier: String {
        "\(self.coordinate.latitude),\(self.coordinate.longitude)"
    }
}

extension MLNAnnotation {
    var identifier: String {
        "\(self.coordinate.latitude),\(self.coordinate.longitude)"
    }
}

extension MapLibreWrapperModel {
    func metersAcrossAtZoomLevel(_ zoomLevel: Double, latitude: CLLocationDegrees, screenWidthPoints: CGFloat, scale: CGFloat = UIScreen.main.scale) -> Double {
        let earthCircumference: Double = 40075016.686
        let tileSize: Double = 256.0
        let latitudeRadians = latitude * Double.pi / 180.0
        let mapPixelSize = tileSize * pow(2.0, zoomLevel)
        let metersPerPixel = (earthCircumference * cos(latitudeRadians)) / mapPixelSize
        let screenWidthPixels = Double(screenWidthPoints) * Double(scale)

        return metersPerPixel * screenWidthPixels
    }
}
