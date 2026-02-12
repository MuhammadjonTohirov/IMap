//
//  File.swift
//  IMap
//
//  Created by Muhammadjon Tohirov on 13/05/25.
//

import Foundation
import MapLibre
import GoogleMaps

public final class UniversalMarker: GMSMarker, MLNAnnotation, UniversalMapMarkerProtocol {
    public typealias AnnotationViewCompletionHandler = (UniversalMarker) -> UIView?
    
    public let id: String
    dynamic public private(set) var coordinate: CLLocationCoordinate2D
    public let annotationView: AnnotationViewCompletionHandler?
    public let reuseIdentifier: String?
    public let view: UIView?
    public private(set) var compensatesForMapBearing: Bool = false
    public private(set) var worldHeading: CLLocationDirection = 0
    
    public init(
        id: String? = nil,
        coordinate: CLLocationCoordinate2D,
        annotationView: AnnotationViewCompletionHandler?,
        tintColor: UIColor = .red
    ) {
        self.id = id ?? coordinate.identifier
        self.coordinate = coordinate
        self.annotationView = annotationView
        self.reuseIdentifier = nil
        self.view = nil
        super.init()
        self.accessibilityLabel = self.id
        self.position = coordinate
    }
    
    public init(
        id: String? = nil,
        coordinate: CLLocationCoordinate2D,
        view: UIView,
        reuseIdentifier: String? = nil,
        tintColor: UIColor = .red
    ) {
        self.id = id ?? coordinate.identifier
        self.coordinate = coordinate
        self.reuseIdentifier = reuseIdentifier ?? self.id
        self.view = view
        self.annotationView = nil
        super.init()
        self.iconView = view
        self.accessibilityLabel = self.id
        self.position = coordinate
    }
    
    @discardableResult
    public func setGroundAnchor(_ point: CGPoint) -> Self {
        guard let view else { return self }
        self.groundAnchor = point
        
        let y = -point.y * view.frame.height
        let x = -point.x * view.frame.width
        
        view.frame = .init(x: x, y: y, width: view.frame.width, height: view.frame.height)
        return self
    }
    
    @discardableResult
    public func set(compensatesForMapBearing enabled: Bool) -> Self {
        self.compensatesForMapBearing = enabled
        return self
    }

    public func set(coordinate: CLLocationCoordinate2D) {
        self.position = coordinate
        self.coordinate = coordinate
    }
    
    public func set(heading: CLLocationDirection) {
        self.worldHeading = heading
        self.rotation = heading
    }
    
    public func set(displayHeading: CLLocationDirection) {
        self.rotation = displayHeading
    }
    
    public func updatePosition(coordinate: CLLocationCoordinate2D, heading: CLLocationDirection) {
        self.position = coordinate
        self.coordinate = coordinate
        self.worldHeading = heading
        self.rotation = heading
    }
    
    public override func copy() -> Any {
        let new = type(of: self).init(
            id: self.id,
            coordinate: self.coordinate,
            view: self.view ?? UIView(),
            reuseIdentifier: self.reuseIdentifier
        )
        new.rotation = self.rotation
        new.compensatesForMapBearing = self.compensatesForMapBearing
        new.worldHeading = self.worldHeading
        return new
    }
}

extension CLLocationCoordinate2D: @retroactive @unchecked Sendable {
    
}
