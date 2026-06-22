@MainActor
public protocol DeviceHeadingProviderDelegate: AnyObject {
    func deviceHeadingProvider(
        _ provider: any DeviceHeadingProviding,
        didUpdate heading: DeviceHeading
    )

    func deviceHeadingProvider(
        _ provider: any DeviceHeadingProviding,
        didUpdateOrientation orientation: DeviceHeadingOrientation
    )

    func deviceHeadingProvider(
        _ provider: any DeviceHeadingProviding,
        didFail error: DeviceHeadingProviderError
    )
}

public extension DeviceHeadingProviderDelegate {
    func deviceHeadingProvider(
        _ provider: any DeviceHeadingProviding,
        didUpdate heading: DeviceHeading
    ) {}

    func deviceHeadingProvider(
        _ provider: any DeviceHeadingProviding,
        didUpdateOrientation orientation: DeviceHeadingOrientation
    ) {}

    func deviceHeadingProvider(
        _ provider: any DeviceHeadingProviding,
        didFail error: DeviceHeadingProviderError
    ) {}
}
