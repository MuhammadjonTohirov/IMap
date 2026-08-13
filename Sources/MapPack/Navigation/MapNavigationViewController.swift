import CoreLocation
import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation
import UIKit

/// A lifecycle wrapper around MapLibre Navigation's `NavigationViewController`.
///
/// The wrapped controller owns a separate map. Creating this wrapper does not alter the
/// existing universal map; location and camera ownership move to the navigation SDK only
/// after this controller appears.
@MainActor
public final class MapNavigationViewController: UIViewController {
    public private(set) var isNavigationActive = false

    /// Called after the SDK's cancel or arrival flow finishes.
    public var onNavigationFinished: (() -> Void)?

    /// Called when a configured Directions-compatible endpoint fails to reroute.
    public var onReroutingFailed: ((Error) -> Void)?

    private let route: MapNavigationRoute
    private let configuration: MapNavigationConfiguration
    private var navigationViewController: NavigationViewController?
    private var hasStartedNavigation = false

    init(
        route: MapNavigationRoute,
        configuration: MapNavigationConfiguration
    ) {
        self.route = route
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let directions = makeDirections()
        let controller = NavigationViewController(
            dayStyleURL: configuration.dayStyleURL,
            nightStyleURL: configuration.nightStyleURL,
            directions: directions,
            voiceController: RouteVoiceController()
        )
        controller.delegate = self
        controller.snapsUserLocationAnnotationToRoute = configuration.snapsUserLocationToRoute
        controller.showsEndOfRouteFeedback = configuration.showsEndOfRouteFeedback
        controller.sendsNotifications = configuration.sendsBackgroundNotifications
        controller.automaticallyAdjustsStyleForTimeOfDay =
            configuration.automaticallyAdjustsStyleForTimeOfDay

        addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        NSLayoutConstraint.activate([
            controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controller.view.topAnchor.constraint(equalTo: view.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        controller.didMove(toParent: self)
        navigationViewController = controller
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startNavigationIfNeeded()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed
            || isMovingFromParent
            || navigationController?.isBeingDismissed == true {
            endNavigation(animated: false)
        }
    }

    /// Stops location, route, voice, and camera work owned by the navigation SDK.
    public func endNavigation(animated: Bool = true) {
        guard isNavigationActive else { return }
        navigationViewController?.endNavigation(animated: animated)
        isNavigationActive = false
    }

    private func startNavigationIfNeeded() {
        guard !hasStartedNavigation, let navigationViewController else { return }
        hasStartedNavigation = true
        isNavigationActive = true

        switch configuration.locationSource {
        case .device:
            navigationViewController.startNavigation(
                with: route.platformRoute,
                animated: true
            )
        case let .simulated(speedMultiplier):
            let locationManager = SimulatedLocationManager(route: route.platformRoute)
            locationManager.speedMultiplier = Self.validatedSpeedMultiplier(speedMultiplier)
            navigationViewController.startNavigation(
                with: route.platformRoute,
                animated: true,
                locationManager: locationManager
            )
        }
    }

    private func makeDirections() -> Directions {
        if let rerouting = configuration.rerouting {
            return Directions(
                accessToken: rerouting.accessToken,
                host: rerouting.host
            )
        }

        // The legacy SDK requires a non-empty token even when its rerouting delegate
        // always returns false. This instance is never used for a network request.
        return Directions(
            accessToken: "imap-rerouting-disabled",
            host: "directions.invalid"
        )
    }

    private static func validatedSpeedMultiplier(_ requestedValue: Double) -> Double {
        guard requestedValue.isFinite, requestedValue > 0 else { return 1 }
        return requestedValue
    }
}

extension MapNavigationViewController: @preconcurrency NavigationViewControllerDelegate {
    public func navigationViewControllerDidFinishRouting(
        _ navigationViewController: NavigationViewController
    ) {
        isNavigationActive = false
        onNavigationFinished?()
    }

    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        shouldRerouteFrom location: CLLocation
    ) -> Bool {
        configuration.rerouting != nil
    }

    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didFailToRerouteWith error: Error
    ) {
        onReroutingFailed?(error)
    }
}
