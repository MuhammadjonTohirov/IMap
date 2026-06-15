//
//  UniversalMapViewController.swift
//  IMap
//
//  Primary UIKit entry point for the Universal Map. It owns the shared
//  `UniversalMapViewModel`, embeds the provider's native map as a child view
//  controller, and overlays the native pin/address UI. The SwiftUI counterpart
//  is `UniversalMapView`; both are thin shells over the same view model.
//

import UIKit

/// A `UIViewController` that hosts the Universal Map for UIKit-based apps.
///
/// ```swift
/// let map = UniversalMapViewController(provider: .mapLibre, config: myConfig)
///     .showsUserLocation(true)
///     .userTrackingMode(true)
/// navigationController?.pushViewController(map, animated: true)
/// // Drive the map through `map.viewModel` (markers, polylines, tracking, …).
/// ```
@MainActor
public final class UniversalMapViewController: UIViewController, UniversalMapConfiguring {

    /// The shared map "brain". Use it for markers, polylines, tracking, etc.
    public let viewModel: UniversalMapViewModel

    private var mapChild: UIViewController?
    private var overlay: MapOverlayUIView?

    /// Create a controller with a specific provider and configuration.
    public init(provider: MapProvider, config: any MapConfigProtocol) {
        self.viewModel = UniversalMapViewModel(mapProvider: provider, config: config)
        super.init(nibName: nil, bundle: nil)
    }

    /// Create a controller around an existing view model (e.g. shared with SwiftUI).
    public init(viewModel: UniversalMapViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        embedMap()
        embedOverlay()
    }

    private func embedMap() {
        let child = viewModel.makeMapViewController()
        addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(child.view)
        NSLayoutConstraint.activate([
            child.view.topAnchor.constraint(equalTo: view.topAnchor),
            child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        child.didMove(toParent: self)
        mapChild = child
    }

    private func embedOverlay() {
        let overlay = MapOverlayUIView(viewModel: viewModel)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        self.overlay = overlay
    }
}
