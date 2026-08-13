//
//  File.swift
//  IMap
//
//  Created by Muhammadjon Tohirov on 14/11/25.
//

import Foundation

public class MapLibreConfig: MapLibreConfigProtocol, @unchecked Sendable {
    public private(set) var darkThemeUrl: URL?
    public private(set) var lightThemeUrl: URL?
    
    public var lightStyle: String
    
    public var darkStyle: String

    /// Whether the user can change the camera pitch with MapLibre's pitch gesture.
    ///
    /// Programmatic camera updates can still set a pitch when this is `false`.
    public var isPitchEnabled: Bool
    
    public init(
        darkThemeUrl: URL? = .init(string: MapLibreLightStyle().source),
        lightThemeUrl: URL? = .init(string: MapLibreLightStyle().source),
        isPitchEnabled: Bool = false
    ) {
        self.darkThemeUrl = darkThemeUrl
        self.lightThemeUrl = lightThemeUrl
        self.isPitchEnabled = isPitchEnabled
        
        self.lightStyle = lightThemeUrl?.absoluteString ?? ""
        self.darkStyle = darkThemeUrl?.absoluteString ?? ""
    }
}
