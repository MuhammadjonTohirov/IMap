import CoreLocation
import GoogleMaps
import UIKit
import XCTest
@testable import MapPack

final class UniversalMapPolylineCasingTests: XCTestCase {
    private let coordinates = [
        CLLocationCoordinate2D(latitude: 40.387189, longitude: 71.806286),
        CLLocationCoordinate2D(latitude: 40.395165, longitude: 71.788777)
    ]

    func testRoutePolylineUsesNavigationPaletteAndWiderCasing() throws {
        let route = UniversalMapPolyline.route(coordinates: coordinates)
        let casing = try XCTUnwrap(route.casing)

        XCTAssertEqual(route.width, 8)
        XCTAssertEqual(casing.width, 12)
        XCTAssertTrue(
            route.color.isEqual(
                UIColor(
                    red: 0,
                    green: 0.498_039_215_7,
                    blue: 0.909_803_921_6,
                    alpha: 1
                )
            )
        )
        XCTAssertTrue(
            casing.color.isEqual(
                UIColor(
                    red: 0,
                    green: 0.345_098_039_2,
                    blue: 0.635_294_117_6,
                    alpha: 1
                )
            )
        )
    }

    func testRoutePolylinePreventsCasingFromBeingNarrowerThanMainLine() throws {
        let route = UniversalMapPolyline.route(
            coordinates: coordinates,
            width: 10,
            casingWidth: 4
        )

        XCTAssertEqual(try XCTUnwrap(route.casing).width, 10)
    }

    func testMapLibreConversionPreservesCasing() throws {
        let route = UniversalMapPolyline.route(coordinates: coordinates)
        let mapLibrePolyline = route.toMapLibrePolyline()

        XCTAssertEqual(mapLibrePolyline.width, route.width)
        XCTAssertEqual(
            try XCTUnwrap(mapLibrePolyline.casing).width,
            try XCTUnwrap(route.casing).width
        )
    }

    @MainActor
    func testGoogleConversionBuildsSynchronizedCasingOverlay() throws {
        let route = UniversalMapPolyline.route(coordinates: coordinates)
        let line = route.gmsPolyline()
        let casing = try XCTUnwrap(route.gmsCasingPolyline())

        XCTAssertEqual(line.path?.count(), 2)
        XCTAssertEqual(casing.path?.count(), line.path?.count())
        XCTAssertEqual(casing.strokeWidth, 12)
        XCTAssertEqual(casing.zIndex, -1)
    }

    @MainActor
    func testStandardPolylineDoesNotCreateGoogleCasingOverlay() {
        let line = UniversalMapPolyline(coordinates: coordinates)

        XCTAssertNil(line.casing)
        XCTAssertNil(line.gmsCasingPolyline())
    }
}
