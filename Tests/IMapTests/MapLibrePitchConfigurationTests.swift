import MapLibre
import XCTest
@testable import MapPack

final class MapLibrePitchConfigurationTests: XCTestCase {
    @MainActor
    func testNativeMapFactoryAppliesEnabledPitchConfiguration() {
        let viewModel = MapLibreWrapperModel()

        let mapView = MapLibreNativeMapFactory.make(
            styleUrl: nil,
            zoomLevel: 15,
            inset: nil,
            showsUserLocation: false,
            isPitchEnabled: true,
            delegate: viewModel
        )

        XCTAssertTrue(mapView.isPitchEnabled)
    }

    @MainActor
    func testPitchRemainsDisabledByDefault() {
        let config = MapLibreConfig()
        let viewModel = MapLibreWrapperModel()
        viewModel.set(config: config)

        let mapView = MapLibreNativeMapFactory.make(
            styleUrl: nil,
            zoomLevel: 15,
            inset: nil,
            showsUserLocation: false,
            isPitchEnabled: viewModel.isPitchEnabled,
            delegate: viewModel
        )

        XCTAssertFalse(mapView.isPitchEnabled)
    }

    @MainActor
    func testUpdatingConfigurationUpdatesExistingMapView() {
        let viewModel = MapLibreWrapperModel()
        let mapView = MapLibreNativeMapFactory.make(
            styleUrl: nil,
            zoomLevel: 15,
            inset: nil,
            showsUserLocation: false,
            isPitchEnabled: false,
            delegate: viewModel
        )
        viewModel.set(mapView: mapView)

        viewModel.set(config: MapLibreConfig(isPitchEnabled: true))
        XCTAssertTrue(mapView.isPitchEnabled)

        viewModel.set(config: MapLibreConfig(isPitchEnabled: false))
        XCTAssertFalse(mapView.isPitchEnabled)
    }
}
