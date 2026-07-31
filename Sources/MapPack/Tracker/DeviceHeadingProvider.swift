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
    private var isObservingDeviceOrientation = false
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

        isUpdatingHeading = true
        locationManager.startUpdatingHeading()
        
        if automaticallyUpdatesHeadingOrientation {
            startObservingDeviceOrientation()
            updateDeviceOrientation(UIDevice.current.orientation)
        }
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
        guard !isObservingDeviceOrientation else { return }

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        isGeneratingDeviceOrientationNotifications = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceOrientationDidChange(_:)),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        isObservingDeviceOrientation = true
    }

    private func stopObservingDeviceOrientation() {
        if isObservingDeviceOrientation {
            NotificationCenter.default.removeObserver(
                self,
                name: UIDevice.orientationDidChangeNotification,
                object: nil
            )
            isObservingDeviceOrientation = false
        }

        if isGeneratingDeviceOrientationNotifications {
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
            isGeneratingDeviceOrientationNotifications = false
        }
    }

    @objc
    private func deviceOrientationDidChange(_ notification: Notification) {
        updateDeviceOrientation(UIDevice.current.orientation)
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
