/// Creates provider-specific turn-by-turn navigation controllers.
@MainActor
public enum MapNavigationViewControllerFactory {
    public static func isSupported(for provider: MapProvider) -> Bool {
        provider == .mapLibre
    }

    /// Returns a lazily configured MapLibre navigation controller.
    ///
    /// Google Maps intentionally returns `nil` until a provider-specific navigation
    /// implementation is introduced.
    public static func makeViewController(
        for provider: MapProvider,
        route: MapNavigationRoute,
        configuration: MapNavigationConfiguration
    ) -> MapNavigationViewController? {
        guard isSupported(for: provider) else { return nil }
        return MapNavigationViewController(
            route: route,
            configuration: configuration
        )
    }
}
