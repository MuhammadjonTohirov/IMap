import CoreLocation
import UIKit

public extension UniversalMapPolyline {
    /// Builds a high-contrast route line using the same two-stroke palette as
    /// MapLibre Navigation's default route presentation.
    static func route(
        id: String = UUID().uuidString,
        coordinates: [CLLocationCoordinate2D],
        color: UIColor = UIColor(
            red: 0,
            green: 0.498_039_215_7,
            blue: 0.909_803_921_6,
            alpha: 1
        ),
        width: CGFloat = 8,
        casingColor: UIColor = UIColor(
            red: 0,
            green: 0.345_098_039_2,
            blue: 0.635_294_117_6,
            alpha: 1
        ),
        casingWidth: CGFloat = 12,
        geodesic: Bool = true,
        title: String? = nil
    ) -> UniversalMapPolyline {
        UniversalMapPolyline(
            id: id,
            coordinates: coordinates,
            color: color,
            width: width,
            geodesic: geodesic,
            title: title,
            casing: UniversalMapPolylineCasing(
                color: casingColor,
                width: max(casingWidth, width)
            )
        )
    }
}
