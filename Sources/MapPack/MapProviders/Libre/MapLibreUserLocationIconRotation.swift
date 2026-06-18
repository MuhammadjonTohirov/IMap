import CoreLocation

enum MapLibreUserLocationIconRotation {
    static func displayRotation(
        for heading: CLLocationDirection,
        mapBearing: CLLocationDirection,
        usesNativeRotatingTrackingMode: Bool
    ) -> CLLocationDirection {
        if usesNativeRotatingTrackingMode {
            return normalizedHeading(heading)
        }

        return normalizedHeading(heading - mapBearing)
    }

    static func normalizedHeading(_ value: CLLocationDirection) -> CLLocationDirection {
        var angle = value.truncatingRemainder(dividingBy: 360)
        if angle < 0 { angle += 360 }
        return angle
    }
}
