import RealityKit
import XCTest
@testable import MapPack

final class UserLocation3DTests: XCTestCase {
    func testUnchangedMapTransformsKeepCachedThreeDimensionalRenderCurrent() {
        var state = MapLibreUserLocation3DRenderState()
        state.invalidate()
        let cachedRevision = state.revision

        XCTAssertFalse(state.setDisplayHeading(0))
        XCTAssertFalse(state.setMapPitch(0))
        XCTAssertTrue(state.isCurrent(cachedRevision))

        XCTAssertTrue(state.setMapPitch(30))
        XCTAssertFalse(state.isCurrent(cachedRevision))
    }

    func testLatestThreeDimensionalRenderRevisionWins() {
        var state = MapLibreUserLocation3DRenderState()
        XCTAssertTrue(state.setDisplayHeading(45))
        let staleRevision = state.revision

        XCTAssertTrue(state.setDisplayHeading(90))

        XCTAssertFalse(state.isCurrent(staleRevision))
        XCTAssertTrue(state.isCurrent(state.revision))
    }

    func testProjectionMatchesMapPitch() {
        let flatPosition = MapLibreUserLocation3DProjection.cameraPosition(
            pitch: 0,
            distance: 3.2
        )
        XCTAssertEqual(flatPosition.x, 0, accuracy: 0.0001)
        XCTAssertEqual(flatPosition.y, 3.2, accuracy: 0.0001)
        XCTAssertEqual(flatPosition.z, 0, accuracy: 0.0001)
        XCTAssertEqual(
            MapLibreUserLocation3DProjection.shadowVerticalScale(pitch: 0),
            1,
            accuracy: 0.0001
        )

        let tiltedPosition = MapLibreUserLocation3DProjection.cameraPosition(
            pitch: 60,
            distance: 3.2
        )
        XCTAssertEqual(tiltedPosition.y, 1.6, accuracy: 0.0001)
        XCTAssertEqual(tiltedPosition.z, 2.7713, accuracy: 0.0001)
        XCTAssertEqual(
            MapLibreUserLocation3DProjection.shadowVerticalScale(pitch: 60),
            0.5,
            accuracy: 0.0001
        )
    }

    func testThreeDimensionalLocationAnchorRemainsCentered() {
        let bounds = CGRect(x: 0, y: 0, width: 84, height: 96)
        let screenAnchor = MapLibreUserLocation3DProjection.screenLocationAnchor(
            in: bounds
        )

        XCTAssertEqual(
            MapLibreUserLocation3DProjection.sceneLocationAnchor,
            SIMD3<Float>.zero
        )
        XCTAssertEqual(screenAnchor.x, bounds.midX, accuracy: 0.0001)
        XCTAssertEqual(screenAnchor.y, bounds.midY, accuracy: 0.0001)
    }

    @MainActor
    func testMapLibreAdvertisesThreeDimensionalLocationCapability() {
        let provider = MapLibreProvider()

        XCTAssertTrue(
            provider.capabilities.contains(.threeDimensionalUserLocation)
        )
    }

    @MainActor
    func testMapLibreCanSwitchFromThreeDimensionalModelBackToStandard() async throws {
        let loader = UserLocation3DModelLoaderStub()
        let provider = MapLibreProvider(userLocation3DModelLoader: loader)

        try await provider.setUserLocationAppearance(.model3D(.carArrow))

        XCTAssertEqual(loader.loadedModels, [.carArrow])
        XCTAssertTrue(provider.hasCustomUserLocationIcon)
        XCTAssertNotNil(provider.viewModel.userLocation3DModelEntity)
        guard case let .model3D(model) = provider.viewModel.userLocationAppearance else {
            return XCTFail("Expected the MapLibre 3D location appearance.")
        }
        XCTAssertEqual(model, .carArrow)

        try await provider.setUserLocationAppearance(.standard)

        XCTAssertFalse(provider.hasCustomUserLocationIcon)
        XCTAssertNil(provider.viewModel.userLocation3DModelEntity)
        guard case .standard = provider.viewModel.userLocationAppearance else {
            return XCTFail("Expected the regular MapLibre location appearance.")
        }
    }

    @MainActor
    func testLatestAppearanceRequestWinsWhileModelIsLoading() async throws {
        let loader = YieldingUserLocation3DModelLoaderStub()
        let provider = MapLibreProvider(userLocation3DModelLoader: loader)
        let modelRequest = Task { @MainActor in
            try await provider.setUserLocationAppearance(.model3D(.carArrow))
        }

        while !loader.didStartLoading {
            await Task.yield()
        }
        try await provider.setUserLocationAppearance(.standard)

        do {
            try await modelRequest.value
            XCTFail("The superseded model request should be cancelled.")
        } catch is CancellationError {
            // Expected: the later regular-marker request owns the final state.
        }

        XCTAssertFalse(provider.hasCustomUserLocationIcon)
        XCTAssertNil(provider.viewModel.userLocation3DModelEntity)
        guard case .standard = provider.viewModel.userLocationAppearance else {
            return XCTFail("Expected the latest regular location appearance.")
        }
    }

    @MainActor
    func testBundledCarArrowLoadsWithGeometry() async throws {
        let loader = BundledUserLocation3DModelLoader()

        let entity = try await loader.loadModel(.carArrow)
        let bounds = entity.visualBounds(recursive: true, relativeTo: entity)

        XCTAssertGreaterThan(bounds.extents.x, 0)
        XCTAssertGreaterThan(bounds.extents.y, 0)
        XCTAssertGreaterThan(bounds.extents.z, 0)
    }

    @MainActor
    func testGoogleRejectsOnlyThreeDimensionalAppearance() async throws {
        let provider = GoogleMapsProvider()

        try await provider.setUserLocationAppearance(.standard)

        do {
            try await provider.setUserLocationAppearance(.model3D(.carArrow))
            XCTFail("Google Maps should reject a 3D current-location model.")
        } catch let error as UserLocationAppearanceError {
            XCTAssertEqual(
                error,
                .unsupportedThreeDimensionalModel(providerName: "Google Maps")
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

@MainActor
private final class UserLocation3DModelLoaderStub: UserLocation3DModelLoading {
    private(set) var loadedModels: [UserLocation3DModel] = []

    func loadModel(_ model: UserLocation3DModel) async throws -> Entity {
        loadedModels.append(model)
        return Entity()
    }
}

@MainActor
private final class YieldingUserLocation3DModelLoaderStub: UserLocation3DModelLoading {
    private(set) var didStartLoading = false

    func loadModel(_ model: UserLocation3DModel) async throws -> Entity {
        didStartLoading = true
        await Task.yield()
        return Entity()
    }
}
