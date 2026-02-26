import CoreLocation

public final class NavigationRouteTrackingSessionManager: NavigationRouteTrackingSessionManaging {
    public var routeCoordinates: [CLLocationCoordinate2D] {
        storedRouteCoordinates
    }

    public var displayHeading: CLLocationDirection {
        storedDisplayHeading
    }

    public var displayCoordinate: CLLocationCoordinate2D? {
        storedDisplayCoordinate
    }

    private let config: NavigationRouteTrackingConfig
    private let headingService: NavigationHeadingComputing

    private var routeTracker: NavigationRouteTrackingManager?
    private var storedRouteCoordinates: [CLLocationCoordinate2D] = []
    private var storedDisplayHeading: CLLocationDirection = 0
    private var storedDisplayCoordinate: CLLocationCoordinate2D?
    private var routeHeadingStrategy: NavigationRouteHeadingStrategy = .lookAhead
    private var latestServerHeading: NavigationServerHeading?
    private var lastHeadingUpdateAt: Date?
    private var lastLocationUpdateAt: Date?

    public init(
        config: NavigationRouteTrackingConfig,
        headingService: NavigationHeadingComputing
    ) {
        self.config = config
        self.headingService = headingService
    }

    public func configureRoute(
        coordinates: [CLLocationCoordinate2D],
        currentLocation: CLLocationCoordinate2D?
    ) -> NavigationRouteSetupState? {
        storedRouteCoordinates = coordinates
        routeTracker = NavigationRouteTrackingManager(
            routeCoordinates: coordinates,
            threshold: config.routeSnapThreshold
        )

        guard let start = coordinates.first else {
            clearRouteState()
            return nil
        }

        let initialCoordinate = currentLocation ?? start
        let initialHeading: CLLocationDirection
        if coordinates.count > 1 {
            initialHeading = headingService.bearing(from: coordinates[0], to: coordinates[1])
        } else {
            initialHeading = 0
        }

        storedDisplayCoordinate = initialCoordinate
        storedDisplayHeading = initialHeading
        lastHeadingUpdateAt = nil
        lastLocationUpdateAt = nil

        return NavigationRouteSetupState(
            routeCoordinates: coordinates,
            initialMarkerCoordinate: initialCoordinate,
            initialHeading: initialHeading
        )
    }

    public func handleLocationUpdate(_ location: CLLocation) -> NavigationRouteTrackingUpdate? {
        guard let routeTracker else {
            return nil
        }

        switch routeTracker.updateDriverLocation(location.coordinate) {
        case .onTrack(let snappedLocation, let remainingPath):
            let nextHeading = headingService.computeTargetHeading(input: .init(
                snappedCoordinate: snappedLocation,
                remainingPath: remainingPath,
                location: location,
                lastDisplayCoordinate: storedDisplayCoordinate,
                currentDisplayHeading: storedDisplayHeading,
                routeHeadingStrategy: routeHeadingStrategy,
                lookAheadDistance: config.routeHeadingLookAheadDistance,
                minReliableCourseSpeed: config.minReliableCourseSpeed,
                serverHeading: latestServerHeading,
                serverHeadingMaxAge: config.serverHeadingMaxAge
            ))

            let deltaTime = headingDeltaTime(at: location.timestamp)
            let smoothedHeading = headingService.smoothHeading(
                from: storedDisplayHeading,
                to: nextHeading,
                factor: config.headingSmoothingFactor,
                deltaTime: deltaTime,
                maxTurnRatePerSecond: config.maxHeadingTurnRatePerSecond
            )
            let transitionDuration = markerTransitionDuration(at: location.timestamp)

            storedDisplayCoordinate = snappedLocation
            storedDisplayHeading = smoothedHeading

            let connectorCoordinates = connectorPath(
                markerCoordinate: snappedLocation,
                remainingPath: remainingPath
            )

            let hasArrived: Bool
            if let destination = storedRouteCoordinates.last {
                hasArrived = headingService.distance(from: snappedLocation, to: destination) <= config.routeArrivalThreshold
            } else {
                hasArrived = false
            }

            return .onTrack(.init(
                markerCoordinate: snappedLocation,
                markerHeading: smoothedHeading,
                markerTransitionDuration: transitionDuration,
                remainingPath: remainingPath,
                connectorCoordinates: connectorCoordinates,
                hasArrived: hasArrived
            ))

        case .outOfRoute:
            return .outOfRoute
        }
    }

    public func resetTrackingState() {
        lastHeadingUpdateAt = nil
        lastLocationUpdateAt = nil
    }

    public func clearRouteState() {
        routeTracker = nil
        storedRouteCoordinates = []
        storedDisplayCoordinate = nil
        storedDisplayHeading = 0
        lastHeadingUpdateAt = nil
        lastLocationUpdateAt = nil
    }

    public func updateServerHeading(_ heading: CLLocationDirection, timestamp: Date) {
        latestServerHeading = NavigationServerHeading(
            value: heading.normalizedHeading,
            timestamp: timestamp
        )
    }

    public func setRouteHeadingStrategy(_ strategy: NavigationRouteHeadingStrategy) {
        routeHeadingStrategy = strategy
    }

    private func headingDeltaTime(at eventTime: Date) -> TimeInterval {
        defer { lastHeadingUpdateAt = eventTime }

        guard let lastHeadingUpdateAt else {
            return 1.0 / 30.0
        }

        return max(1.0 / 60.0, min(1.0, eventTime.timeIntervalSince(lastHeadingUpdateAt)))
    }

    private func connectorPath(
        markerCoordinate: CLLocationCoordinate2D,
        remainingPath: [CLLocationCoordinate2D]
    ) -> [CLLocationCoordinate2D]? {
        guard let routeStartCoordinate = remainingPath.first else {
            return nil
        }

        let connectorDistance = headingService.distance(
            from: markerCoordinate,
            to: routeStartCoordinate
        )
        guard connectorDistance > config.connectorHideThreshold else {
            return nil
        }

        return [markerCoordinate, routeStartCoordinate]
    }

    private func markerTransitionDuration(at eventTime: Date) -> TimeInterval {
        defer { lastLocationUpdateAt = eventTime }

        guard let lastLocationUpdateAt else {
            return config.markerAnimationFallbackDuration
        }

        let rawDelta = eventTime.timeIntervalSince(lastLocationUpdateAt)
        guard rawDelta.isFinite, rawDelta > 0 else {
            return config.markerAnimationFallbackDuration
        }

        return max(
            config.markerAnimationMinDuration,
            min(config.markerAnimationMaxDuration, rawDelta)
        )
    }
}

private extension CLLocationDirection {
    var normalizedHeading: CLLocationDirection {
        var value = truncatingRemainder(dividingBy: 360)
        if value < 0 { value += 360 }
        return value
    }
}
