//
//  UniversalMapEdgeInsets.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

// UniversalMap/Models/UniversalMapEdgeInsets.swift
import Foundation
import UIKit
import MapLibre

/// A universal edge insets model that works with any map provider
public struct UniversalMapEdgeInsets {
    /// The inset values
    public var insets: UIEdgeInsets
    /// Whether to animate inset changes
    public var animated: Bool
    /// Completion handler called after insets are applied
    public var onEnd: (() -> Void)?
    
    public init(
        top: CGFloat = 0,
        left: CGFloat = 0,
        bottom: CGFloat = 0,
        right: CGFloat = 0,
        animated: Bool = false,
        onEnd: (() -> Void)? = nil
    ) {
        self.insets = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        self.animated = animated
        self.onEnd = onEnd
    }
    
    /// Convert to MapLibre edge insets
    internal func toMapLibreEdgeInsets() -> MapEdgeInsets {
        return MapEdgeInsets(
            insets: insets,
            animated: animated,
            onEnd: onEnd
        )
    }
}
