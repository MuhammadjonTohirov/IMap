//
//  MapLibreMapViewController.swift
//  IMap
//
//  Native UIKit host for a MapLibre map. Mirrors the behaviour of the SwiftUI
//  `MapLibreMapView` / `MLNMapViewWrapper` (native-view construction, delegate
//  wiring, camera/tracking application, color-scheme updates and the
//  did-become-active user-location refresh) without involving SwiftUI.
//

import UIKit
import SwiftUI
import MapLibre

@MainActor
final class MapLibreMapViewController: UIViewController {
    private let viewModel: MapLibreWrapperModel
    private let mapDelegate: MLNMapViewDelegate
    private let initialCamera: MapCamera?
    private let styleUrl: String?
    private let inset: MapEdgeInsets?
    private let showsUserLocation: Bool

    private var mapView: MLNMapView?
    private var didApplyInitialCamera = false

    init(
        viewModel: MapLibreWrapperModel,
        delegate: MLNMapViewDelegate,
        camera: MapCamera?,
        styleUrl: String?,
        inset: MapEdgeInsets?,
        showsUserLocation: Bool
    ) {
        self.viewModel = viewModel
        self.mapDelegate = delegate
        self.initialCamera = camera
        self.styleUrl = styleUrl
        self.inset = inset
        self.showsUserLocation = showsUserLocation
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let mapView = MapLibreNativeMapFactory.make(
            styleUrl: styleUrl,
            zoomLevel: viewModel.zoomLevel,
            inset: inset,
            showsUserLocation: showsUserLocation,
            delegate: mapDelegate
        )
        self.mapView = mapView
        self.view = mapView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let mapView else { return }

        // Mirror `MLNMapViewWrapper.updateUIView`: hand the map to the model and
        // apply tracking / user-location state once.
        viewModel.set(mapView: mapView)

        let requestedTrackingMode = viewModel.requestedUserTrackingMode.maplibre
        if mapView.userTrackingMode != requestedTrackingMode {
            mapView.userTrackingMode = requestedTrackingMode
        }
        if mapView.showsUserLocation != showsUserLocation {
            mapView.showsUserLocation = showsUserLocation
        }

        viewModel.onChangeColorScheme(currentColorScheme)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyInitialCameraIfNeeded()
        viewModel.drainPendingActionsIfReady()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle else { return }
        viewModel.onChangeColorScheme(currentColorScheme)
    }

    private var currentColorScheme: ColorScheme {
        traitCollection.userInterfaceStyle == .dark ? .dark : .light
    }

    private func applyInitialCameraIfNeeded() {
        guard !didApplyInitialCamera, let initialCamera, let mapView else { return }
        didApplyInitialCamera = true
        mapView.setCamera(initialCamera.camera, animated: initialCamera.animate)
    }

    /// Re-arms the user-location layer after the app returns to the foreground,
    /// matching the SwiftUI wrapper's `didBecomeActive` handling.
    @objc private func handleDidBecomeActive() {
        guard showsUserLocation, let mapView else { return }
        mapView.showsUserLocation = false
        mapView.showsUserLocation = true
        mapView.userTrackingMode = viewModel.requestedUserTrackingMode.maplibre
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
