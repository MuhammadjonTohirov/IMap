//
//  UniversalMapStyles.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

// UniversalMap/Models/UniversalMapStyle.swift
import Foundation
import GoogleMaps

public protocol UniversalMapStyleProtocol {
    var source: String {get}
}

public struct GoogleLightMapStyle: UniversalMapStyleProtocol {
    public var source: String {
        GMapStyles.default
    }
}

public struct GoogleDarkMapStyle: UniversalMapStyleProtocol {
    public var source: String {
        GMapStyles.dark
    }
}
