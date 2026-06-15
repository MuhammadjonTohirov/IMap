//
//  UniversalMapContainerView.swift
//  IMap
//
//  A plain `UIView` wrapper around `UniversalMapViewController` for callers that
//  prefer a view over a controller. It performs proper child view-controller
//  containment by locating the nearest parent controller through the responder
//  chain, so the underlying provider (e.g. Google's `GMSMapView`) still receives
//  its view-controller lifecycle callbacks.
//

import UIKit

/// A `UIView` that embeds the Universal Map. Add it to any view hierarchy whose
/// owning view controller is reachable via the responder chain.
///
/// ```swift
/// let mapView = UniversalMapContainerView(provider: .google, config: myConfig)
/// mapView.showsUserLocation(true)
/// view.addSubview(mapView)               // inside a UIViewController
/// // Drive the map through `mapView.viewModel`.
/// ```
@MainActor
public final class UniversalMapContainerView: UIView, UniversalMapConfiguring {

    /// The shared map "brain". Use it for markers, polylines, tracking, etc.
    public let viewModel: UniversalMapViewModel

    private var mapController: UniversalMapViewController?

    /// Create a container with a specific provider and configuration.
    public init(provider: MapProvider, config: any MapConfigProtocol) {
        self.viewModel = UniversalMapViewModel(mapProvider: provider, config: config)
        super.init(frame: .zero)
    }

    /// Create a container around an existing view model (e.g. shared with SwiftUI).
    public init(viewModel: UniversalMapViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            attachIfNeeded()
        } else {
            detach()
        }
    }

    private func attachIfNeeded() {
        guard mapController == nil, let parent = parentViewController else { return }
        let controller = UniversalMapViewController(viewModel: viewModel)
        parent.addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(controller.view)
        NSLayoutConstraint.activate([
            controller.view.topAnchor.constraint(equalTo: topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            controller.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        controller.didMove(toParent: parent)
        mapController = controller
    }

    private func detach() {
        guard let controller = mapController else { return }
        controller.willMove(toParent: nil)
        controller.view.removeFromSuperview()
        controller.removeFromParent()
        mapController = nil
    }
}
