import CoreLocation
import UIKit

/// Device orientation values that are useful for compass heading correction.
public enum DeviceHeadingOrientation: Equatable, Sendable {
    case portrait
    case portraitUpsideDown
    case landscapeLeft
    case landscapeRight

    public init?(_ deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait:
            self = .portrait
        case .portraitUpsideDown:
            self = .portraitUpsideDown
        case .landscapeLeft:
            self = .landscapeLeft
        case .landscapeRight:
            self = .landscapeRight
        case .faceUp, .faceDown, .unknown:
            return nil
        @unknown default:
            return nil
        }
    }

    public init?(_ interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait:
            self = .portrait
        case .portraitUpsideDown:
            self = .portraitUpsideDown
        case .landscapeLeft:
            self = .landscapeLeft
        case .landscapeRight:
            self = .landscapeRight
        case .unknown:
            return nil
        @unknown default:
            return nil
        }
    }

    var coreLocationOrientation: CLDeviceOrientation {
        switch self {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        }
    }
}
