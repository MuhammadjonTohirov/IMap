import Combine
import CoreLocation
import UIKit

/// Core Location-backed provider for device compass heading.
@MainActor
public final class DeviceHeadingProvider: NSObject, ObservableObject, DeviceHeadingProviding {
    @Published public private(set) var currentHeading: DeviceHeading?
    @Published public private(set) var headingOrientation: DeviceHeadingOrientation
    @Published public private(set) var isUpdatingHeading = false

    public weak var delegate: DeviceHeadingProviderDelegate?

    public var isHeadingAvailable: Bool {
        CLLocationManager.headingAvailable()
    }

    private let locationManager: CLLocationManager
    private let automaticallyUpdatesHeadingOrientation: Bool
    private var orientationObserver: NSObjectProtocol?
    private var isGeneratingDeviceOrientationNotifications = false

    public init(
        headingFilter: CLLocationDegrees = 1,
        headingOrientation: DeviceHeadingOrientation = .portrait,
        automaticallyUpdatesHeadingOrientation: Bool = true
    ) {
        self.locationManager = CLLocationManager()
        self.headingOrientation = headingOrientation
        self.automaticallyUpdatesHeadingOrientation = automaticallyUpdatesHeadingOrientation
        super.init()

        locationManager.delegate = self
        locationManager.headingFilter = headingFilter
        locationManager.headingOrientation = headingOrientation.coreLocationOrientation
    }

    deinit {
        locationManager.stopUpdatingHeading()
        locationManager.delegate = nil

        if let orientationObserver {
            NotificationCenter.default.removeObserver(orientationObserver)
        }

        if isGeneratingDeviceOrientationNotifications {
            DispatchQueue.main.async {
                UIDevice.current.endGeneratingDeviceOrientationNotifications()
            }
        }
    }

    public func startUpdatingHeading() {
        guard isHeadingAvailable else {
            let error = DeviceHeadingProviderError.headingUnavailable
            Logging.l(tag: "DeviceHeadingProvider", error.localizedDescription)
            delegate?.deviceHeadingProvider(self, didFail: error)
            return
        }

        if automaticallyUpdatesHeadingOrientation {
            startObservingDeviceOrientation()
            updateDeviceOrientation(UIDevice.current.orientation)
        }

        isUpdatingHeading = true
        locationManager.startUpdatingHeading()
    }

    public func stopUpdatingHeading() {
        guard isUpdatingHeading else { return }

        locationManager.stopUpdatingHeading()
        stopObservingDeviceOrientation()
        isUpdatingHeading = false
    }

    public func updateHeadingOrientation(_ orientation: DeviceHeadingOrientation) {
        guard headingOrientation != orientation else {
            locationManager.headingOrientation = orientation.coreLocationOrientation
            return
        }

        headingOrientation = orientation
        locationManager.headingOrientation = orientation.coreLocationOrientation
        delegate?.deviceHeadingProvider(self, didUpdateOrientation: orientation)
    }

    public func updateDeviceOrientation(_ orientation: UIDeviceOrientation) {
        guard let headingOrientation = DeviceHeadingOrientation(orientation) else { return }
        updateHeadingOrientation(headingOrientation)
    }

    public func updateInterfaceOrientation(_ orientation: UIInterfaceOrientation) {
        guard let headingOrientation = DeviceHeadingOrientation(orientation) else { return }
        updateHeadingOrientation(headingOrientation)
    }

    private func startObservingDeviceOrientation() {
        guard orientationObserver == nil else { return }

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        isGeneratingDeviceOrientationNotifications = true

        orientationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateDeviceOrientation(UIDevice.current.orientation)
            }
        }
    }

    private func stopObservingDeviceOrientation() {
        if let orientationObserver {
            NotificationCenter.default.removeObserver(orientationObserver)
            self.orientationObserver = nil
        }

        if isGeneratingDeviceOrientationNotifications {
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
            isGeneratingDeviceOrientationNotifications = false
        }
    }
}

extension DeviceHeadingProvider: @MainActor CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard let heading = DeviceHeading(newHeading) else { return }

        currentHeading = heading
        delegate?.deviceHeadingProvider(self, didUpdate: heading)
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let providerError = DeviceHeadingProviderError.make(from: error)
        Logging.l(tag: "DeviceHeadingProvider", providerError.localizedDescription)
        delegate?.deviceHeadingProvider(self, didFail: providerError)
    }
}
