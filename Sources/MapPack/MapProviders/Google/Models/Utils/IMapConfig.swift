//
//  File.swift
//  YallaKit
//
//  Created by Muhammadjon Tohirov on 15/04/25.
//

import Foundation
import SwiftUI
import UIKit

public struct MapTheme: Sendable {
    /// Default theme colors. Defined programmatically (not via an asset catalog) so
    /// they always resolve when IMap is consumed as an external package, regardless
    /// of the host app's bundle. Consumers can override the whole palette by assigning
    /// `MapTheme.colors` with their own brand colors.
    @MainActor
    public static var colors: Colors = .init(
        iAction: Color(red: 0, green: 0, blue: 0),
        iPrimary: Color(red: 139.0 / 255.0, green: 62.0 / 255.0, blue: 252.0 / 255.0),
        pinLabel: .white,
        pinOverlayCircle: .white
    )
    
    public struct Colors {
        public var iAction: Color
        public var iPrimary: Color
        public var pinLabel: Color
        public var pinOverlayCircle: Color = .white
    }
}

public protocol MapConfigProtocol: Sendable {
    var hasAddressChangeAnimation: Bool { get set }
    var mapConfiguration: any UniversalMapConfigProtocol { get set}
}

public struct MapConfig: MapConfigProtocol {
    public var hasAddressChangeAnimation: Bool = true
    public var mapConfiguration: any UniversalMapConfigProtocol
    
    public init(config: UniversalMapConfigProtocol, hasAddressChangeAnimation: Bool = true) {
        self.hasAddressChangeAnimation = hasAddressChangeAnimation
        self.mapConfiguration = config
    }
}


@MainActor
extension Color {
    static var iAction: Color {
        MapTheme.colors.iAction
    }

    static var iPrimary: Color {
        MapTheme.colors.iPrimary
    }

    static var pinLabel: Color {
        MapTheme.colors.pinLabel
    }

    static var pinOverlayCircle: Color {
        MapTheme.colors.pinOverlayCircle
    }
}

/// UIKit mirror of the theme colors so the native (UIKit) overlay shares the
/// single ``MapTheme`` source of truth instead of duplicating asset lookups.
@MainActor
extension UIColor {
    static var iAction: UIColor { UIColor(Color.iAction) }

    static var iPrimary: UIColor { UIColor(Color.iPrimary) }

    static var pinLabel: UIColor { UIColor(Color.pinLabel) }

    static var pinOverlayCircle: UIColor { UIColor(Color.pinOverlayCircle) }
}

