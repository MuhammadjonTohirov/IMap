//
//  UniversalMapMarker.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

// UniversalMap/Models/UniversalMapMarker.swift
import Foundation
import CoreLocation
import UIKit
import GoogleMaps
import MapLibre

/// A universal marker model that works with any map provider
public struct UniversalMapMarker: Identifiable {
    /// Unique identifier for the marker
    public let id: String
    /// Geographic position of the marker
    public var coordinate: CLLocationCoordinate2D
    /// Title text displayed in the marker's info window
    public var title: String?
    /// Subtitle text displayed in the marker's info window
    public var subtitle: String?
    /// Icon image for the marker
    public var icon: UIImage?
    /// Tint color for the marker
    public var tintColor: UIColor
    /// Whether the info window should appear when the marker is tapped
    public var showsInfoWindow: Bool
    /// Z-index value controls the drawing order of markers
    public var zIndex: Int
    /// Whether the marker is draggable
    public var isDraggable: Bool
    
    public init(
        id: String = UUID().uuidString,
        coordinate: CLLocationCoordinate2D,
        title: String? = nil,
        subtitle: String? = nil,
        icon: UIImage? = UIImage(systemName: "mappin"),
        tintColor: UIColor = .red,
        showsInfoWindow: Bool = true,
        zIndex: Int = 0,
        isDraggable: Bool = false
    ) {
        self.id = id
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.tintColor = tintColor
        self.showsInfoWindow = showsInfoWindow
        self.zIndex = zIndex
        self.isDraggable = isDraggable
    }
    
    /// Converts to a Google Maps marker
    internal func toGMSMarker() -> GMSMarker {
        let marker = GMSMarker()
        marker.position = coordinate
        marker.title = title
        marker.snippet = subtitle
        if let icon = icon {
            marker.icon = icon.withTintColor(tintColor)
        }
        marker.appearAnimation = .pop
        marker.zIndex = Int32(zIndex)
        marker.accessibilityLabel = id
        marker.isDraggable = isDraggable
        
        return marker
    }
    
    /// Converts to a MapLibre marker
    internal func toMapLibreMarker() -> MapMarker {
        return MapMarker(
            id: id,
            coordinate: coordinate,
            title: title,
            subtitle: subtitle,
            image: icon,
            tintColor: tintColor
        )
    }
}
