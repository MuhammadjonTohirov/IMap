import XCTest
import CoreLocation
import SwiftUI
import UIKit
import MapLibre
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

    @MainActor
    func testUniversalMapViewModelForwardsTintColorToProvider() {
        let provider = TintRecordingMapProvider()
        let viewModel = UniversalMapViewModel(
            instance: provider,
            providerType: .mapLibre,
            config: MapConfig(config: TestUniversalMapConfig())
        )

        viewModel.setTintColor(.systemBlue)

        XCTAssertTrue(provider.tintColor?.isEqual(UIColor.systemBlue) == true)
    }

    @MainActor
    func testUniversalMapViewModelSetDirectionUpdatesCachedBearing() {
        let provider = TintRecordingMapProvider()
        let viewModel = UniversalMapViewModel(
            instance: provider,
            providerType: .mapLibre,
            config: MapConfig(config: TestUniversalMapConfig())
        )
        viewModel.updateCamera(
            to: UniversalMapCamera(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                zoom: 12,
                bearing: 0
            )
        )

        viewModel.setDirection(135, animated: false)

        XCTAssertEqual(viewModel.camera?.bearing, 135)
    }

    @MainActor
    func testUniversalMapViewModelReadsMapLibreZoomLevelDirectly() throws {
        let provider = MapLibreProvider()
        let mapView = MLNMapView(
            frame: CGRect(x: 0, y: 0, width: 390, height: 844),
            styleURL: nil
        )
        provider.viewModel.set(mapView: mapView)
        let viewModel = UniversalMapViewModel(
            instance: provider,
            providerType: .mapLibre,
            config: MapConfig(config: TestUniversalMapConfig()),
            deviceHeadingProvider: FakeDeviceHeadingProvider(),
            locationTrackingManager: LocationTrackingManager(locationManager: CoreLocationManagerSpy())
        )
        mapView.zoomLevel = 15.75

        let camera = try XCTUnwrap(viewModel.getCamera(animate: false))

        XCTAssertEqual(camera.zoom, 15.75, accuracy: 0.0001)
        XCTAssertFalse(camera.animate)
    }

    @MainActor
    func testMapLibreUpdateCameraPreservesRequestedZoom() throws {
        let provider = MapLibreProvider()
        let mapView = MLNMapView(
            frame: CGRect(x: 0, y: 0, width: 390, height: 844),
            styleURL: nil
        )
        provider.viewModel.set(mapView: mapView)
        let viewModel = UniversalMapViewModel(
            instance: provider,
            providerType: .mapLibre,
            config: MapConfig(config: TestUniversalMapConfig()),
            deviceHeadingProvider: FakeDeviceHeadingProvider(),
            locationTrackingManager: LocationTrackingManager(locationManager: CoreLocationManagerSpy())
        )

        viewModel.updateCamera(
            to: UniversalMapCamera(
                center: CLLocationCoordinate2D(latitude: 41.31, longitude: 69.28),
                zoom: 16.25,
                bearing: 70,
                pitch: 25,
                animate: false
            )
        )

        let camera = try XCTUnwrap(viewModel.getCamera(animate: false))
        XCTAssertEqual(camera.zoom, 16.25, accuracy: 0.0001)
        XCTAssertEqual(camera.pitch, 25, accuracy: 0.0001)
    }

    @MainActor
    func testUserTrackingModeIsOwnedByUniversalMapViewModelForBothProviders() {
        for providerType in [MapProvider.google, .mapLibre] {
            let provider = TintRecordingMapProvider()
            provider.capabilities = [.userTrackingMode]
            let coreLocationManager = CoreLocationManagerSpy()
            let headingProvider = FakeDeviceHeadingProvider()
            let viewModel = UniversalMapViewModel(
                instance: provider,
                providerType: providerType,
                config: MapConfig(config: TestUniversalMapConfig()),
                deviceHeadingProvider: headingProvider,
                locationTrackingManager: LocationTrackingManager(locationManager: coreLocationManager)
            )

            XCTAssertTrue(viewModel.setUserTrackingMode(.course))

            XCTAssertEqual(viewModel.userTrackingMode, .course)
            XCTAssertEqual(provider.nativeTrackingModes.last, UserLocationtrackingMode.none)
            XCTAssertEqual(coreLocationManager.startUpdatingLocationCount, 1)
            XCTAssertTrue(headingProvider.isUpdatingHeading)
        }
    }

    @MainActor
    func testCourseTrackingUsesLocationCourseBeforeCompassHeading() async throws {
        let provider = TintRecordingMapProvider()
        let headingProvider = FakeDeviceHeadingProvider()
        let viewModel = UniversalMapViewModel(
            instance: provider,
            providerType: .google,
            config: MapConfig(config: TestUniversalMapConfig()),
            deviceHeadingProvider: headingProvider,
            locationTrackingManager: LocationTrackingManager(locationManager: CoreLocationManagerSpy())
        )
        viewModel.updateCamera(to: UniversalMapCamera(center: .init(latitude: 0, longitude: 0), zoom: 14, bearing: 10))
        headingProvider.sendHeading(270)

        XCTAssertTrue(viewModel.setUserTrackingMode(.course))
        viewModel.locationTrackingManager.currentLocation = trackedLocation(
            latitude: 41,
            longitude: 69,
            course: 90
        )
        await Task.yield()

        let camera = try XCTUnwrap(viewModel.camera)
        XCTAssertEqual(camera.bearing, 90)
        XCTAssertEqual(camera.center.latitude, 41, accuracy: 0.0001)
        XCTAssertEqual(camera.center.longitude, 69, accuracy: 0.0001)
    }

    @MainActor
    func testCourseTrackingFallsBackToCompassWhenLocationCourseIsInvalid() async throws {
        let provider = TintRecordingMapProvider()
        let headingProvider = FakeDeviceHeadingProvider()
        let viewModel = UniversalMapViewModel(
            instance: provider,
            providerType: .google,
            config: MapConfig(config: TestUniversalMapConfig()),
            deviceHeadingProvider: headingProvider,
            locationTrackingManager: LocationTrackingManager(locationManager: CoreLocationManagerSpy())
        )
        viewModel.updateCamera(to: UniversalMapCamera(center: .init(latitude: 0, longitude: 0), zoom: 14, bearing: 10))
        headingProvider.sendHeading(120)

        XCTAssertTrue(viewModel.setUserTrackingMode(.course))
        viewModel.locationTrackingManager.currentLocation = trackedLocation(
            latitude: 41,
            longitude: 69,
            course: -1
        )
        await Task.yield()

        let camera = try XCTUnwrap(viewModel.camera)
        XCTAssertEqual(camera.bearing, 120)
        XCTAssertEqual(camera.center.latitude, 41, accuracy: 0.0001)
        XCTAssertEqual(camera.center.longitude, 69, accuracy: 0.0001)
    }

    @MainActor
    func testHeadingTrackingFollowsLocationWithoutChangingDirection() async throws {
        let provider = TintRecordingMapProvider()
        let headingProvider = FakeDeviceHeadingProvider()
        let viewModel = UniversalMapViewModel(
            instance: provider,
            providerType: .google,
            config: MapConfig(config: TestUniversalMapConfig()),
            deviceHeadingProvider: headingProvider,
            locationTrackingManager: LocationTrackingManager(locationManager: CoreLocationManagerSpy())
        )
        viewModel.updateCamera(to: UniversalMapCamera(center: .init(latitude: 0, longitude: 0), zoom: 14, bearing: 33))

        XCTAssertTrue(viewModel.setUserTrackingMode(.heading))
        viewModel.locationTrackingManager.currentLocation = trackedLocation(
            latitude: 42,
            longitude: 70,
            course: 180
        )
        await Task.yield()

        let camera = try XCTUnwrap(viewModel.camera)
        XCTAssertEqual(camera.bearing, 33)
        XCTAssertEqual(camera.center.latitude, 42, accuracy: 0.0001)
        XCTAssertEqual(camera.center.longitude, 70, accuracy: 0.0001)
        XCTAssertFalse(headingProvider.isUpdatingHeading)
    }

    @MainActor
    func testUserGestureCancelsTrackingModeAndNotifiesDelegate() {
        let provider = TintRecordingMapProvider()
        let headingProvider = FakeDeviceHeadingProvider()
        let delegate = TrackingModeRecordingDelegate()
        let viewModel = UniversalMapViewModel(
            instance: provider,
            providerType: .mapLibre,
            config: MapConfig(config: TestUniversalMapConfig()),
            deviceHeadingProvider: headingProvider,
            locationTrackingManager: LocationTrackingManager(locationManager: CoreLocationManagerSpy())
        )
        viewModel.setInteractionDelegate(delegate)

        XCTAssertTrue(viewModel.setUserTrackingMode(.course))
        viewModel.mapDidStartDragging()

        XCTAssertEqual(viewModel.userTrackingMode, .none)
        XCTAssertFalse(headingProvider.isUpdatingHeading)
        XCTAssertEqual(
            delegate.changes,
            [
                .init(mode: .course, reason: .programmatic),
                .init(mode: .none, reason: .userInteraction)
            ]
        )
    }
}

private struct TestUniversalMapConfig: UniversalMapConfigProtocol {
    var lightStyle: String = ""
    var darkStyle: String = ""
}

private final class TintRecordingMapProvider: NSObject, MapProviderProtocol {
    private(set) var tintColor: UIColor?
    private(set) var updatedCameras: [UniversalMapCamera] = []
    private(set) var nativeTrackingModes: [UserLocationtrackingMode] = []
    var capabilities: MapCapabilities = []
    var currentLocation: CLLocation?
    var markers: [String: any UniversalMapMarkerProtocol] = [:]
    var polylines: [String: UniversalMapPolyline] = [:]

    required override init() {
        super.init()
    }

    func updateCamera(to camera: UniversalMapCamera) {
        updatedCameras.append(camera)
    }

    func setEdgeInsets(_ insets: UniversalMapEdgeInsets) {}

    func setMaxMinZoomLevels(min: Double, max: Double) {}

    func focusMap(on coordinate: CLLocationCoordinate2D, zoom: Double?, animated: Bool) {}

    func focusOnPolyline(id: String, padding: UIEdgeInsets, animated: Bool) {}

    func focusOnPolyline(id: String, animated: Bool) {}

    func focusOn(coordinates: [CLLocationCoordinate2D], edges: UIEdgeInsets, animated: Bool) {}

    @MainActor
    func zoomOut(minLevel: Float, shift: Double) {}

    func addMarker(_ marker: any UniversalMapMarkerProtocol) {}

    func marker(byId id: String) -> (any UniversalMapMarkerProtocol)? {
        markers[id]
    }

    func updateMarker(_ marker: any UniversalMapMarkerProtocol) {}

    func removeMarker(withId id: String) {}

    func clearAllMarkers() {}

    func addPolyline(_ polyline: UniversalMapPolyline, animated: Bool) {}

    func updatePolyline(_ polyline: UniversalMapPolyline, animated: Bool) {}

    func updatePolyline(id: String, coordinates: [CLLocationCoordinate2D], animated: Bool) {}

    func removePolyline(withId id: String) {}

    func clearAllPolylines() {}

    func showUserLocation(_ show: Bool) {}

    func setUserTrackingMode(mode: UserLocationtrackingMode) {
        nativeTrackingModes.append(mode)
    }

    func set(preferredRefreshRate: MapRefreshRate) {}

    func setMapStyle(_ style: (any UniversalMapStyleProtocol)?, scheme: ColorScheme) {}

    @MainActor
    func setTintColor(_ color: UIColor) {
        tintColor = color
    }

    func showBuildings(_ show: Bool) {}

    func setConfig(_ config: any UniversalMapConfigProtocol) {}

    func setInteractionDelegate(_ delegate: MapInteractionDelegate?) {}

    @MainActor
    func set(disabled: Bool) {}

    func makeMapView() -> AnyView {
        AnyView(EmptyView())
    }

    @MainActor
    func makeMapViewController() -> UIViewController {
        UIViewController()
    }
}

@MainActor
private final class FakeDeviceHeadingProvider: DeviceHeadingProviding {
    private(set) var currentHeading: DeviceHeading?
    private(set) var headingOrientation: DeviceHeadingOrientation = .portrait
    private(set) var isUpdatingHeading = false
    var isHeadingAvailable = true
    weak var delegate: DeviceHeadingProviderDelegate?

    func startUpdatingHeading() {
        isUpdatingHeading = true
    }

    func stopUpdatingHeading() {
        isUpdatingHeading = false
    }

    func updateHeadingOrientation(_ orientation: DeviceHeadingOrientation) {
        headingOrientation = orientation
    }

    func updateDeviceOrientation(_ orientation: UIDeviceOrientation) {}

    func updateInterfaceOrientation(_ orientation: UIInterfaceOrientation) {}

    func sendHeading(_ degrees: CLLocationDirection) {
        guard let heading = DeviceHeading(
            trueHeading: degrees,
            magneticHeading: -1,
            accuracy: 1
        ) else { return }

        currentHeading = heading
        delegate?.deviceHeadingProvider(self, didUpdate: heading)
    }
}

@MainActor
private final class CoreLocationManagerSpy: CoreLocationManaging {
    weak var delegate: CLLocationManagerDelegate?
    var desiredAccuracy: CLLocationAccuracy = 0
    var distanceFilter: CLLocationDistance = 0
    var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse

    private(set) var requestWhenInUseAuthorizationCount = 0
    private(set) var startUpdatingLocationCount = 0
    private(set) var stopUpdatingLocationCount = 0

    func requestWhenInUseAuthorization() {
        requestWhenInUseAuthorizationCount += 1
    }

    func startUpdatingLocation() {
        startUpdatingLocationCount += 1
    }

    func stopUpdatingLocation() {
        stopUpdatingLocationCount += 1
    }
}

private struct TrackingModeChange: Equatable {
    let mode: UserLocationtrackingMode
    let reason: UserTrackingModeChangeReason
}

@MainActor
private final class TrackingModeRecordingDelegate: UniversalMapViewModelDelegate {
    private(set) var changes: [TrackingModeChange] = []

    func mapDidChangeUserTrackingMode(
        map: MapProviderProtocol,
        mode: UserLocationtrackingMode,
        reason: UserTrackingModeChangeReason
    ) {
        changes.append(.init(mode: mode, reason: reason))
    }
}

private func trackedLocation(
    latitude: CLLocationDegrees,
    longitude: CLLocationDegrees,
    course: CLLocationDirection
) -> CLLocation {
    CLLocation(
        coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
        altitude: 0,
        horizontalAccuracy: 5,
        verticalAccuracy: 5,
        course: course,
        courseAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
        timestamp: Date()
    )
}
