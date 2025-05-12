//
//  MapMarker.swift
//  LibreMap
//
//  Created by Muhammadjon Tohirov on 07/05/25.
//
// MapMarker.swift

import Foundation
import MapLibre
import UIKit

public struct MapMarker: Identifiable {
    public let id: String
    public let coordinate: CLLocationCoordinate2D
    public let title: String?
    public let subtitle: String?
    public let image: UIImage?
    public let tintColor: UIColor
    
    public init(id: String = UUID().uuidString,
                coordinate: CLLocationCoordinate2D,
                title: String? = nil,
                subtitle: String? = nil,
                image: UIImage? = UIImage(systemName: "mappin"),
                tintColor: UIColor = .red) {
        self.id = id
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.tintColor = tintColor
    }
}
