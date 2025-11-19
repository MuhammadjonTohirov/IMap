//
//  MapLibreWrapper.swift
//  LibreMap
//`
//  Created by Muhammadjon Tohirov on 06/05/25.
//
// MapLibreWrapper.swift

import Foundation
import MapLibre
import SwiftUI

public struct MLNMapViewWrapper: UIViewRepresentable {
    @ObservedObject var viewModel: MapLibreWrapperModel
    var delegate: MLNMapViewDelegate
    var camera: MapCamera?
    var styleUrl: String?
    var inset: MapEdgeInsets?
    var trackingMode: MLNUserTrackingMode?
    var showsUserLocation: Bool = true
    
    public init(
        viewModel: MapLibreWrapperModel,
        delegate: MLNMapViewDelegate,
        camera: MapCamera? = nil,
        styleUrl: String? = nil,
        inset: MapEdgeInsets? = nil,
        trackingMode: MLNUserTrackingMode? = nil,
        showsUserLocation: Bool = true
    ) {
        self.viewModel = viewModel
        self.delegate = delegate
        self.camera = camera
        self.styleUrl = styleUrl
        self.inset = inset
        self.trackingMode = trackingMode
        self.showsUserLocation = showsUserLocation
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    public typealias UIViewType = MLNMapView
    
    public func makeUIView(context: Context) -> MLNMapView {
        let styleURL = URL(string: styleUrl ?? "https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json")
        
        let view = MLNMapView(frame: .zero, styleURL: styleURL)
        view.showsUserLocation = showsUserLocation
        view.zoomLevel = viewModel.zoomLevel
        view.showsUserHeadingIndicator = true
        view.prefetchesTiles = false
        view.isMultipleTouchEnabled = false
        view.tileCacheEnabled = true
        view.isPitchEnabled = false
        view.isHapticFeedbackEnabled = true
        view.delegate = delegate
        
        view.anchorRotateOrZoomGesturesToCenterCoordinate = true
        view.attributionButton.isHidden = true
        view.logoView.isHidden = true
        return view
    }
    
    public func updateUIView(_ uiView: MLNMapView, context: Context) {
        // Keep delegate assigned to the model (avoid losing it to other code paths)
        if uiView.delegate !== delegate {
            uiView.delegate = delegate
        }

        // Provide mapView to model and gesture setup
        viewModel.set(mapView: uiView)
        viewModel.setupGestureLocker()

        // Apply inset first so camera computation uses the final viewport
        if let inset = inset {
            uiView.setContentInset(inset.insets, animated: inset.animated, completionHandler: inset.onEnd)
        }
        
        // Apply tracking mode before camera to avoid overrides
        if let trackingMode = trackingMode, uiView.userTrackingMode != trackingMode {
            uiView.userTrackingMode = trackingMode
        }
        
        // User location visibility
        if uiView.showsUserLocation != showsUserLocation {
            uiView.showsUserLocation = showsUserLocation
        }

        // Apply initial camera last (if provided externally)
        if let camera = camera {
            uiView.setCamera(camera.camera, animated: camera.animate)
        }
        
        // If we are already in a window, force a layout pass and try to drain pending camera actions
        if uiView.window != nil {
            uiView.setNeedsLayout()
            uiView.layoutIfNeeded()
            viewModel.drainPendingActionsIfReady()
        }
    }
    
    public final class Coordinator: NSObject {
        public var parent: MLNMapViewWrapper
        
        public init(parent: MLNMapViewWrapper) {
            self.parent = parent
        }
    }
}
