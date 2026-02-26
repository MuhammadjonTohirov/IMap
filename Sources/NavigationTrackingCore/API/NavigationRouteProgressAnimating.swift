import CoreLocation

public protocol NavigationRouteProgressAnimating: AnyObject {
    func animate(
        from startProgress: CLLocationDistance,
        to targetProgress: CLLocationDistance,
        duration: TimeInterval,
        onUpdate: @escaping (CLLocationDistance) -> Void,
        onCompletion: (() -> Void)?
    )

    func cancel()
}
