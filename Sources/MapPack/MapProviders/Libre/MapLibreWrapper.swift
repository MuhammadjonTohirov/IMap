//
//  MapLibreWrapper.swift
//  LibreMap
//
//  Created by Muhammadjon Tohirov on 06/05/25.
//
// MapLibreWrapper.swift

import Foundation
import MapLibre
import SwiftUI

public struct MLNMapViewWrapper: UIViewRepresentable {
    @ObservedObject var viewModel: MapLibreWrapperModel
    var camera: MapCamera?
    var styleUrl: String?
    var inset: MapEdgeInsets?
    var trackingMode: MLNUserTrackingMode?
    var showsUserLocation: Bool = true
    
    public init(
        viewModel: MapLibreWrapperModel,
        camera: MapCamera? = nil,
        styleUrl: String? = nil,
        inset: MapEdgeInsets? = nil,
        trackingMode: MLNUserTrackingMode? = nil,
        showsUserLocation: Bool = true
    ) {
        self.viewModel = viewModel
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
        view.delegate = viewModel
        view.prefetchesTiles = true
        view.isMultipleTouchEnabled = false
        view.tileCacheEnabled = true
        view.isPitchEnabled = false
        view.isHapticFeedbackEnabled = false
        viewModel.set(mapView: view)
        viewModel.setupGestureLocker()
        view.anchorRotateOrZoomGesturesToCenterCoordinate = true
        view.attributionButton.isHidden = true
        view.logoView.isHidden = true
        return view
    }
    
    public func updateUIView(_ uiView: MLNMapView, context: Context) {
        uiView.delegate = viewModel

        if let camera = camera {
            uiView.setCamera(camera.camera, animated: camera.animate)
        }
        
        if let inset = inset {
            uiView.setContentInset(inset.insets, animated: inset.animated, completionHandler: inset.onEnd)
        }
        
        if let trackingMode = trackingMode {
            uiView.userTrackingMode = trackingMode
        }
        
        uiView.showsUserLocation = showsUserLocation
    }
    
    public final class Coordinator: NSObject {
        public var parent: MLNMapViewWrapper
        
        public init(parent: MLNMapViewWrapper) {
            self.parent = parent
        }
    }
}
