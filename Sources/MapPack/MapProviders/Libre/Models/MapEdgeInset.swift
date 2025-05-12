//
//  MapEdgeInset.swift
//  LibreMap
//
//  Created by Muhammadjon Tohirov on 07/05/25.
//

import Foundation
import MapLibre

public struct MapEdgeInsets {
    public var insets: UIEdgeInsets
    public var animated: Bool
    public var onEnd: (() -> Void)?

    public init(
        top: CGFloat = 0,
        leading: CGFloat = 0,
        bottom: CGFloat = 0,
        trailing: CGFloat = 0,
        animated: Bool = false,
        onEnd: (() -> Void)? = nil,
    ) {
        self.insets = .init(top: top, left: leading, bottom: bottom, right: trailing)
        self.animated = animated
        self.onEnd = onEnd
    }
    
    public init (insets: UIEdgeInsets, animated: Bool = false, onEnd: (() -> Void)? = nil) {
        self.insets = insets
        self.animated = animated
        self.onEnd = onEnd
    }
}


