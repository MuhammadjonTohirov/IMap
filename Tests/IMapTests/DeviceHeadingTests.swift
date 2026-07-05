import CoreLocation
import XCTest
import UIKit
@testable import MapPack

final class DeviceHeadingTests: XCTestCase {
    func testDeviceHeadingPrefersTrueHeadingWhenValid() {
        let heading = DeviceHeading(
            trueHeading: 42,
            magneticHeading: 48,
            accuracy: 3
        )

        XCTAssertEqual(heading?.degrees, 42)
        XCTAssertEqual(heading?.accuracy, 3)
        XCTAssertEqual(heading?.source, .trueNorth)
    }

    func testDeviceHeadingFallsBackToMagneticHeadingWhenTrueHeadingIsInvalid() {
        let heading = DeviceHeading(
            trueHeading: -1,
            magneticHeading: 48,
            accuracy: 3
        )

        XCTAssertEqual(heading?.degrees, 48)
        XCTAssertEqual(heading?.source, .magneticNorth)
    }

    func testDeviceHeadingRejectsInvalidAccuracy() {
        let heading = DeviceHeading(
            trueHeading: 42,
            magneticHeading: 48,
            accuracy: -1
        )

        XCTAssertNil(heading)
    }

    func testDeviceOrientationMapsOnlyCompassUsefulOrientations() {
        XCTAssertEqual(DeviceHeadingOrientation(UIDeviceOrientation.portrait), .portrait)
        XCTAssertEqual(DeviceHeadingOrientation(UIDeviceOrientation.portraitUpsideDown), .portraitUpsideDown)
        XCTAssertEqual(DeviceHeadingOrientation(UIDeviceOrientation.landscapeLeft), .landscapeLeft)
        XCTAssertEqual(DeviceHeadingOrientation(UIDeviceOrientation.landscapeRight), .landscapeRight)
        XCTAssertNil(DeviceHeadingOrientation(UIDeviceOrientation.faceUp))
        XCTAssertNil(DeviceHeadingOrientation(UIDeviceOrientation.faceDown))
        XCTAssertNil(DeviceHeadingOrientation(UIDeviceOrientation.unknown))
    }
}
