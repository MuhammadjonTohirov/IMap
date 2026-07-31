import UIKit

/// Visual presentation used for the map's current-location annotation.
public enum UserLocationAppearance {
    /// Use the map SDK's regular current-location indicator.
    case standard

    /// Use a screen-aligned image marker.
    case image(UIImage, scale: CGFloat)

    /// Use a live 3D marker. Currently supported by MapLibre only.
    case model3D(UserLocation3DModel)
}
