import Foundation
import CoreLocation

package extension CLLocationCoordinate2D {
    /// Initial great-circle bearing in degrees (0 = north, clockwise) toward `other`.
    /// Returns `nil` when the two coordinates are identical.
    func bearing(to other: CLLocationCoordinate2D) -> CLLocationDirection? {
        let lat1 = latitude * .pi / 180
        let lon1 = longitude * .pi / 180
        let lat2 = other.latitude * .pi / 180
        let lon2 = other.longitude * .pi / 180

        let deltaLon = lon2 - lon1
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)

        guard x != 0 || y != 0 else { return nil }

        var heading = atan2(y, x) * 180 / .pi
        heading = heading.truncatingRemainder(dividingBy: 360)
        if heading < 0 { heading += 360 }
        return heading
    }
}
