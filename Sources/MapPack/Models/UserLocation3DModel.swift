import CoreGraphics
import CoreLocation

/// Configuration for a bundled 3D current-location model.
public struct UserLocation3DModel: Equatable, Sendable {
    /// 3D model resources shipped by `MapPack`.
    public enum Asset: String, Equatable, Sendable {
        case carArrow = "car_arrow"
    }

    /// The bundled model to render.
    public let asset: Asset

    /// Size of the transparent marker viewport in screen points.
    public let viewportSize: CGSize

    /// Scale applied after the model is normalized to fit its viewport.
    public let relativeScale: Float

    /// Clockwise correction applied when the source model's forward axis differs
    /// from north.
    public let headingOffset: CLLocationDirection

    public init(
        asset: Asset,
        viewportSize: CGSize = CGSize(width: 84, height: 96),
        relativeScale: Float = 0.82,
        headingOffset: CLLocationDirection = 0
    ) {
        self.asset = asset
        self.viewportSize = viewportSize
        self.relativeScale = relativeScale
        self.headingOffset = headingOffset
    }

    /// The car-arrow USDZ bundled with `MapPack`.
    public static let carArrow = UserLocation3DModel(asset: .carArrow)
}
