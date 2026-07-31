import Foundation

/// Location updates used by a navigation session.
public enum MapNavigationLocationSource: Sendable, Equatable {
    /// Follow the device's Core Location updates.
    case device

    /// Replay the supplied route. Intended for development and integration testing.
    case simulated(speedMultiplier: Double)
}

/// Credentials for off-route recalculation through a Directions-compatible endpoint.
///
/// Leave this configuration unset when the app's routing server is the source of truth.
/// In that mode `NavigationViewController` still snaps and tracks progress, but it will
/// not attempt to contact Mapbox when the driver leaves the route.
public struct MapNavigationReroutingConfiguration: Sendable, Equatable {
    let accessToken: String
    let host: String?

    public init?(accessToken: String, host: String? = nil) {
        let trimmedToken = accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedToken.isEmpty else { return nil }

        let trimmedHost = host?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.accessToken = trimmedToken
        self.host = trimmedHost?.isEmpty == false ? trimmedHost : nil
    }
}

/// Presentation and behavior options for a MapLibre turn-by-turn session.
public struct MapNavigationConfiguration: Sendable, Equatable {
    public var dayStyleURL: URL
    public var nightStyleURL: URL?
    public var locationSource: MapNavigationLocationSource
    public var rerouting: MapNavigationReroutingConfiguration?
    public var snapsUserLocationToRoute: Bool
    public var showsEndOfRouteFeedback: Bool
    public var sendsBackgroundNotifications: Bool
    public var automaticallyAdjustsStyleForTimeOfDay: Bool

    public init(
        dayStyleURL: URL,
        nightStyleURL: URL? = nil,
        locationSource: MapNavigationLocationSource = .device,
        rerouting: MapNavigationReroutingConfiguration? = nil,
        snapsUserLocationToRoute: Bool = true,
        showsEndOfRouteFeedback: Bool = true,
        sendsBackgroundNotifications: Bool = false,
        automaticallyAdjustsStyleForTimeOfDay: Bool = true
    ) {
        self.dayStyleURL = dayStyleURL
        self.nightStyleURL = nightStyleURL
        self.locationSource = locationSource
        self.rerouting = rerouting
        self.snapsUserLocationToRoute = snapsUserLocationToRoute
        self.showsEndOfRouteFeedback = showsEndOfRouteFeedback
        self.sendsBackgroundNotifications = sendsBackgroundNotifications
        self.automaticallyAdjustsStyleForTimeOfDay = automaticallyAdjustsStyleForTimeOfDay
    }
}
