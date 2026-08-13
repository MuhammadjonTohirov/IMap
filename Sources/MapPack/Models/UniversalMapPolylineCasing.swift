import UIKit

/// A wider stroke rendered underneath a universal polyline.
///
/// Casings keep route geometry readable over roads and map labels without requiring
/// callers to manage a second polyline and keep both geometries synchronized.
public struct UniversalMapPolylineCasing {
    public var color: UIColor
    public var width: CGFloat

    public init(color: UIColor, width: CGFloat) {
        self.color = color
        self.width = width
    }
}
