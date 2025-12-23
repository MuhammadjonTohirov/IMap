//
//  File.swift
//  IMap
//
//  Created by Muhammadjon Tohirov on 14/11/25.
//

import Foundation

public class MapLibreConfig: UniversalMapConfigProtocol, @unchecked Sendable {
    public private(set) var darkThemeUrl: URL?
    public private(set) var lightThemeUrl: URL?
    
    public var lightStyle: String
    
    public var darkStyle: String
    
    public init(darkThemeUrl: URL? = .init(string: MapLibreLightStyle().source), lightThemeUrl: URL? = .init(string: MapLibreLightStyle().source)) {
        self.darkThemeUrl = darkThemeUrl
        self.lightThemeUrl = lightThemeUrl
        
        self.lightStyle = lightThemeUrl?.absoluteString ?? ""
        self.darkStyle = darkThemeUrl?.absoluteString ?? ""
    }
}
