import CoreGraphics
import CoreLocation

struct MapLibreUserLocation3DRenderState {
    private enum Constants {
        static let transformTolerance = 0.0001
    }

    private(set) var displayHeading: CLLocationDirection = 0
    private(set) var mapPitch: CGFloat = 0
    private(set) var revision: UInt = 0

    mutating func setDisplayHeading(_ degrees: CLLocationDirection) -> Bool {
        guard abs(displayHeading - degrees) > Constants.transformTolerance else {
            return false
        }

        displayHeading = degrees
        invalidate()
        return true
    }

    mutating func setMapPitch(_ degrees: CGFloat) -> Bool {
        guard abs(mapPitch - degrees) > Constants.transformTolerance else {
            return false
        }

        mapPitch = degrees
        invalidate()
        return true
    }

    mutating func invalidate() {
        revision &+= 1
    }

    func isCurrent(_ candidateRevision: UInt) -> Bool {
        revision == candidateRevision
    }
}
