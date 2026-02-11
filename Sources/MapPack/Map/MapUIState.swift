//
//  MapUIState.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

import Foundation
import SwiftUI
import CoreLocation

/// Encapsulates the UI state of the map overlay
public struct MapUIState {
    public var hasAddressPicker: Bool = true
    public var hasAddressView: Bool = true
    public var addressInfo: AddressInfo?
    public var pinModel: PinViewModel = .init()
    public var showUserLocation: Bool = true
    public var userTrackingMode: Bool = false
    public var edgeInsets = UniversalMapEdgeInsets()
    
    public init() {}
    
    public var pinViewBottomOffset: CGFloat {
        let sarea = UIApplication.shared.safeArea
        let bottomOffset = self.edgeInsets.insets.bottom - sarea.top
        return bottomOffset
    }
}
