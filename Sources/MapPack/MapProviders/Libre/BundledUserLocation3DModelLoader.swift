import Combine
import Foundation
import RealityKit

@MainActor
final class BundledUserLocation3DModelLoader: UserLocation3DModelLoading {
    private var cachedModels: [UserLocation3DModel.Asset: Entity] = [:]

    func loadModel(_ model: UserLocation3DModel) async throws -> Entity {
        if let cachedModel = cachedModels[model.asset] {
            return cachedModel
        }

        let resourceName = model.asset.rawValue
        guard let resourceURL = modelResourceURL(for: model.asset) else {
            throw UserLocationAppearanceError.missingModelResource(name: resourceName)
        }

        do {
            let entity: Entity
            if #available(iOS 18, *) {
                entity = try await Entity(contentsOf: resourceURL)
            } else {
                entity = try await loadLegacyModel(from: resourceURL, named: resourceName)
            }

            try Task.checkCancellation()
            cachedModels[model.asset] = entity
            return entity
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as UserLocationAppearanceError {
            throw error
        } catch {
            throw UserLocationAppearanceError.modelLoadingFailed(
                name: resourceName,
                reason: error.localizedDescription
            )
        }
    }

    private func modelResourceURL(for asset: UserLocation3DModel.Asset) -> URL? {
        Bundle.module.url(
            forResource: asset.rawValue,
            withExtension: "usdz",
            subdirectory: "UserLocationModels"
        ) ?? Bundle.module.url(forResource: asset.rawValue, withExtension: "usdz")
    }

    @available(iOS, introduced: 16.6, obsoleted: 18)
    private func loadLegacyModel(from url: URL, named name: String) async throws -> Entity {
        for try await entity in Entity.loadAsync(contentsOf: url).values {
            return entity
        }

        throw UserLocationAppearanceError.modelLoadingFailed(
            name: name,
            reason: "RealityKit completed without producing an entity."
        )
    }
}
