import XCTest
@testable import MapPack

final class IMapTests: XCTestCase {
    func testNativeCourseTrackingKeepsCustomUserIconRotation() {
        let rotation = MapLibreUserLocationIconRotation.displayRotation(
            for: 90,
            mapBearing: 90,
            usesNativeRotatingTrackingMode: true
        )

        XCTAssertEqual(rotation, 90)
    }

    func testManualCameraTrackingCompensatesCustomUserIconForMapBearing() {
        let rotation = MapLibreUserLocationIconRotation.displayRotation(
            for: 90,
            mapBearing: 30,
            usesNativeRotatingTrackingMode: false
        )

        XCTAssertEqual(rotation, 60)
    }
}
