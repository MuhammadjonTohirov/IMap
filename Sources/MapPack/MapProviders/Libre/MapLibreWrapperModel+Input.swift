//
//  File.swift
//  IMap
//
//  Created by Muhammadjon Tohirov on 14/11/25.
//

import Foundation

public class MapLibreInput: UniversalMapInputProvider, @unchecked Sendable {
    public private(set) var darkThemeUrl: URL?
    public private(set) var lightThemeUrl: URL?
    
    public init(darkThemeUrl: URL? = nil, lightThemeUrl: URL? = nil) {
        self.darkThemeUrl = darkThemeUrl
        self.lightThemeUrl = lightThemeUrl
    }
}
