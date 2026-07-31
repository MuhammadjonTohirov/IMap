import CoreLocation
import XCTest
@testable import MapPack

final class MapNavigationTests: XCTestCase {
    func testGeometryRouteBuildsMinimalNavigationSteps() throws {
        let route = try makeRoute()

        XCTAssertEqual(route.coordinates.count, 3)
        XCTAssertEqual(route.distance, 1_250)
        XCTAssertEqual(route.expectedTravelTime, 180)
        XCTAssertEqual(route.platformRoute.legs.count, 1)
        XCTAssertEqual(route.platformRoute.legs.first?.steps.count, 3)
        XCTAssertEqual(
            route.platformRoute.legs.first?.steps.dropLast().last?.maneuverType.description,
            "continue"
        )
        XCTAssertEqual(route.platformRoute.legs.first?.steps.last?.maneuverType.description, "arrive")
    }

    func testGeometryRouteRejectsInsufficientCoordinates() {
        XCTAssertThrowsError(
            try MapNavigationRoute(
                coordinates: [.init(latitude: 41.3111, longitude: 69.2797)],
                distance: 100,
                expectedTravelTime: 30
            )
        ) { error in
            XCTAssertEqual(error as? MapNavigationRouteError, .insufficientCoordinates)
        }
    }

    func testGeometryRouteRejectsInvalidCoordinate() {
        XCTAssertThrowsError(
            try MapNavigationRoute(
                coordinates: [
                    .init(latitude: 41.3111, longitude: 69.2797),
                    .init(latitude: 100, longitude: 69.29)
                ],
                distance: 100,
                expectedTravelTime: 30
            )
        ) { error in
            XCTAssertEqual(
                error as? MapNavigationRouteError,
                .invalidCoordinate(index: 1)
            )
        }
    }

    func testGeometryRouteRejectsZeroLengthCoordinates() {
        let coordinate = CLLocationCoordinate2D(latitude: 41.3111, longitude: 69.2797)

        XCTAssertThrowsError(
            try MapNavigationRoute(
                coordinates: [coordinate, coordinate],
                distance: 100,
                expectedTravelTime: 30
            )
        ) { error in
            XCTAssertEqual(error as? MapNavigationRouteError, .zeroLengthRoute)
        }
    }

    @MainActor
    func testFactoryLeavesGoogleNavigationUnsupported() throws {
        let route = try makeRoute()
        let styleURL = try XCTUnwrap(
            URL(string: "https://basemaps.cartocdn.com/gl/positron-gl-style/style.json")
        )
        let configuration = MapNavigationConfiguration(dayStyleURL: styleURL)

        XCTAssertFalse(MapNavigationViewControllerFactory.isSupported(for: .google))
        XCTAssertNil(
            MapNavigationViewControllerFactory.makeViewController(
                for: .google,
                route: route,
                configuration: configuration
            )
        )
    }

    @MainActor
    func testMapLibreControllerIsLazyUntilPresented() throws {
        let controller = try makeController()

        XCTAssertTrue(MapNavigationViewControllerFactory.isSupported(for: .mapLibre))
        XCTAssertFalse(controller.isViewLoaded)
        XCTAssertFalse(controller.isNavigationActive)
    }

    @MainActor
    func testMapLibreControllerStartsAndStopsSimulatedNavigation() throws {
        let controller = try makeController()
        controller.loadViewIfNeeded()

        XCTAssertFalse(controller.isNavigationActive)
        XCTAssertEqual(controller.children.count, 1)

        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()
        XCTAssertTrue(controller.isNavigationActive)

        controller.endNavigation(animated: false)
        XCTAssertFalse(controller.isNavigationActive)
    }

    @MainActor
    func testSimulatedNavigationDoesNotFinishOnFirstLocationUpdate() async throws {
        let controller = try makeController()
        var didFinish = false
        controller.onNavigationFinished = {
            didFinish = true
        }
        controller.loadViewIfNeeded()

        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()
        try await Task<Never, Never>.sleep(nanoseconds: 1_250_000_000)

        XCTAssertFalse(didFinish)
        XCTAssertTrue(controller.isNavigationActive)
        controller.endNavigation(animated: false)
    }

    @MainActor
    func testOnlyMapLibreAdvertisesTurnByTurnCapability() {
        XCTAssertTrue(
            MapLibreProvider().capabilities.contains(.turnByTurnNavigation)
        )
        XCTAssertFalse(
            GoogleMapsProvider().capabilities.contains(.turnByTurnNavigation)
        )
    }

    private func makeRoute() throws -> MapNavigationRoute {
        try MapNavigationRoute(
            coordinates: [
                .init(latitude: 41.3111, longitude: 69.2797),
                .init(latitude: 41.3120, longitude: 69.2850),
                .init(latitude: 41.3150, longitude: 69.2900)
            ],
            distance: 1_250,
            expectedTravelTime: 180
        )
    }

    @MainActor
    private func makeController() throws -> MapNavigationViewController {
        let route = try makeRoute()
        let styleURL = try XCTUnwrap(
            URL(string: "https://basemaps.cartocdn.com/gl/positron-gl-style/style.json")
        )
        let configuration = MapNavigationConfiguration(
            dayStyleURL: styleURL,
            locationSource: .simulated(speedMultiplier: 2),
            showsEndOfRouteFeedback: false
        )

        return try XCTUnwrap(
            MapNavigationViewControllerFactory.makeViewController(
                for: .mapLibre,
                route: route,
                configuration: configuration
            )
        )
    }
}
