import CoreLocation

public struct NavigationServerHeading {
    public let value: CLLocationDirection
    public let timestamp: Date

    public init(value: CLLocationDirection, timestamp: Date) {
        self.value = value
        self.timestamp = timestamp
    }
}
