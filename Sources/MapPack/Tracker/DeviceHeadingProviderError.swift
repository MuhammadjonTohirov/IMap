import CoreLocation

public enum DeviceHeadingProviderError: Error, Equatable, LocalizedError {
    case headingUnavailable
    case coreLocation(CLError.Code)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .headingUnavailable:
            return "Device heading is unavailable on this device."
        case .coreLocation(let code):
            return "Core Location heading error: \(code.rawValue)"
        case .unknown(let description):
            return description
        }
    }

    static func make(from error: Error) -> DeviceHeadingProviderError {
        if let clError = error as? CLError {
            return .coreLocation(clError.code)
        }

        return .unknown(error.localizedDescription)
    }
}
