//
//  UniversalMapStyles.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

// UniversalMap/Models/UniversalMapStyle.swift
import Foundation
import GoogleMaps

/// Represents available map styles across providers
public enum UniversalMapStyle {
    case light
    case dark
    
    /// Get the MapLibre style URL for a given style
    var mapLibreStyleURL: String {
        switch self {
        case .light:
            return MapLibreConfig.shared.liteStyleUrl?.absoluteString ?? ""
        case .dark:
            return MapLibreConfig.shared.darkStyleUrl?.absoluteString ?? ""
        }
    }
    
    /// Convert to Google Maps map type
    var googleMapStyle: String {
        switch self {
        case .light:
            return GMapStyles.default
        case .dark:
            return GMapStyles.dark
        }
    }
}
