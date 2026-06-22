import CoreLocation
import UIKit

@MainActor
public protocol DeviceHeadingProviding: AnyObject {
    var currentHeading: DeviceHeading? { get }
    var headingOrientation: DeviceHeadingOrientation { get }
    var isUpdatingHeading: Bool { get }
    var isHeadingAvailable: Bool { get }
    var delegate: DeviceHeadingProviderDelegate? { get set }

    func startUpdatingHeading()
    func stopUpdatingHeading()
    func updateHeadingOrientation(_ orientation: DeviceHeadingOrientation)
    func updateDeviceOrientation(_ orientation: UIDeviceOrientation)
    func updateInterfaceOrientation(_ orientation: UIInterfaceOrientation)
}
