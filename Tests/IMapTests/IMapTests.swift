import XCTest
import CoreLocation
import SwiftUI
import UIKit
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
}

private struct TestUniversalMapConfig: UniversalMapConfigProtocol {
    var lightStyle: String = ""
    var darkStyle: String = ""
}

private final class TintRecordingMapProvider: NSObject, MapProviderProtocol {
    private(set) var tintColor: UIColor?
    var capabilities: MapCapabilities = []
    var currentLocation: CLLocation?
    var markers: [String: any UniversalMapMarkerProtocol] = [:]
    var polylines: [String: UniversalMapPolyline] = [:]

    required override init() {
        super.init()
    }

    func updateCamera(to camera: UniversalMapCamera) {}

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

    func setUserTrackingMode(mode: UserLocationtrackingMode) {}

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
