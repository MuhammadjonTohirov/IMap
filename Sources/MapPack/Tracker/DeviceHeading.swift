import CoreLocation

/// A validated compass heading for the device.
public struct DeviceHeading: Equatable, Sendable {
    /// Heading in degrees clockwise from north.
    public let degrees: CLLocationDirection
    /// Core Location's estimated heading accuracy in degrees.
    public let accuracy: CLLocationDirection
    /// Whether the heading is relative to true north or magnetic north.
    public let source: DeviceHeadingSource

    public init?(
        trueHeading: CLLocationDirection,
        magneticHeading: CLLocationDirection,
        accuracy: CLLocationDirection
    ) {
        guard accuracy >= 0 else { return nil }

        if trueHeading >= 0 {
            self.degrees = trueHeading
            self.source = .trueNorth
        } else if magneticHeading >= 0 {
            self.degrees = magneticHeading
            self.source = .magneticNorth
        } else {
            return nil
        }

        self.accuracy = accuracy
    }

    init?(_ heading: CLHeading) {
        self.init(
            trueHeading: heading.trueHeading,
            magneticHeading: heading.magneticHeading,
            accuracy: heading.headingAccuracy
        )
    }
}
