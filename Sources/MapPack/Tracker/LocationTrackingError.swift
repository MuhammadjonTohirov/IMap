import CoreLocation

public enum LocationTrackingError: Error, Equatable, LocalizedError {
    case permissionDenied
    case coreLocation(CLError.Code)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied or Location Services disabled."
        case .coreLocation(let code):
            return "Core Location error: \(code.rawValue)"
        case .unknown(let description):
            return description
        }
    }

    static func make(from error: Error) -> LocationTrackingError {
        if let clError = error as? CLError {
            return .coreLocation(clError.code)
        }

        return .unknown(error.localizedDescription)
    }
}
