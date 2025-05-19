//
//  File.swift
//  YallaKit
//
//  Created by Muhammadjon Tohirov on 15/04/25.
//

import Foundation
import SwiftUI

public struct MapTheme: Sendable {
    @MainActor
    public static var colors: Colors = .init(iAction: Color("IAction"), iPrimary: Color("IPrimary"))
    
    public struct Colors {
        public var iAction: Color
        public var iPrimary: Color
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
}

