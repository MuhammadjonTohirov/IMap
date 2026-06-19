//
//  GoogleMapConfig.swift
//  IMap
//
//  Created by applebro on 10/09/24.
//

import Foundation
import GoogleMaps

public struct GMSServicesConfig: Sendable {
    @MainActor static var didConfig = false
    
    /// - key: default if nill or empty
    /// - Once the config is set second time will not be initialized due to confition check
    @MainActor
    public static func setupAPIKey(_ key: String?) {
        guard let key else { return }

        guard !didConfig else { return }
        didConfig = true

        Logging.l("Setup GoogleMap API Key with \(key)")
        
        GMSServices.provideAPIKey(key)
    }
}
