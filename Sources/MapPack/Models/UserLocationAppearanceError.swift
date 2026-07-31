import Foundation

/// Failures produced while changing the current-location appearance.
public enum UserLocationAppearanceError: Error, Equatable {
    /// The selected provider cannot render a live 3D current-location model.
    case unsupportedThreeDimensionalModel(providerName: String)

    /// The requested model is not present in the `MapPack` resource bundle.
    case missingModelResource(name: String)

    /// RealityKit could not decode or prepare the requested model.
    case modelLoadingFailed(name: String, reason: String)
}

extension UserLocationAppearanceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .unsupportedThreeDimensionalModel(providerName):
            return "\(providerName) does not support 3D current-location models."
        case let .missingModelResource(name):
            return "The bundled 3D current-location model '\(name)' is missing."
        case let .modelLoadingFailed(name, reason):
            return "The 3D current-location model '\(name)' could not be loaded: \(reason)"
        }
    }
}
