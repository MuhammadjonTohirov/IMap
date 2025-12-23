//
//  File.swift
//  IMap
//
//  Created by Muhammadjon Tohirov on 23/12/25.
//

import Foundation

public struct GoogleMapsConfig: GoogleMapsConfigProtocol {
    public var lightStyle: String
    
    public var darkStyle: String
    
    public var accessKey: String
    
    public init(
        lightStyle: String = GoogleLightMapStyle().source,
        darkStyle: String = GoogleDarkMapStyle().source,
        accessKey: String = "AIzaSyC_dHd88uaz8yUlmxKbvXo7n-a7mPhgaWI"
    ) {
        self.lightStyle = lightStyle
        self.darkStyle = darkStyle
        self.accessKey = accessKey
    }
}
