import RealityKit

@MainActor
protocol UserLocation3DModelLoading: AnyObject {
    func loadModel(_ model: UserLocation3DModel) async throws -> Entity
}
