import CoreLocation

/// A provider-neutral 3D map marker.
///
/// The marker's identity is stable across updates. Providers can therefore move,
/// rotate, and rescale the existing rendered object instead of loading or creating
/// another model for each navigation update.
public struct UniversalMap3DMarker: @preconcurrency UniversalMapMarkerProtocol, Sendable {
    public let id: String
    public var coordinate: CLLocationCoordinate2D
    public var heading: CLLocationDirection
    public var scale: Float
    public var model: UserLocation3DModel

    public var rotation: CLLocationDirection { heading }
    public var worldHeading: CLLocationDirection { heading }

    public init(
        id: String,
        coordinate: CLLocationCoordinate2D,
        heading: CLLocationDirection,
        scale: Float? = nil,
        model: UserLocation3DModel = .carArrow
    ) {
        self.id = id
        self.coordinate = coordinate
        self.heading = heading
        self.scale = scale ?? model.relativeScale
        self.model = model
    }

    public static func == (
        lhs: UniversalMap3DMarker,
        rhs: UniversalMap3DMarker
    ) -> Bool {
        lhs.id == rhs.id
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
            && lhs.heading == rhs.heading
            && lhs.scale == rhs.scale
            && lhs.model == rhs.model
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
        hasher.combine(heading)
        hasher.combine(scale)
        hasher.combine(model.asset.rawValue)
        hasher.combine(model.viewportSize.width)
        hasher.combine(model.viewportSize.height)
        hasher.combine(model.relativeScale)
        hasher.combine(model.headingOffset)
    }
}
