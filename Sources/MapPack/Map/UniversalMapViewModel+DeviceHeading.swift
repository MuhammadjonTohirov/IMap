//
//  File.swift
//  IMap
//
//  Created by applebro on 22/06/26.
//

import Foundation

// MARK: - DeviceHeadingProviderDelegate Implementation
extension UniversalMapViewModel: DeviceHeadingProviderDelegate {
    public func deviceHeadingProvider(
        _ provider: any DeviceHeadingProviding,
        didUpdate heading: DeviceHeading
    ) {
        latestDeviceHeading = heading

        guard uiState.userTrackingMode == .course,
              let currentLocation = locationTrackingManager.currentLocation,
              currentLocation.course < 0 else { return }

        setDirection(heading.degrees, animated: true)
    }
}
