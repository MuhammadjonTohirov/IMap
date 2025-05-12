//
//  View+.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder
    func visibility(_ visibile: Bool) -> some View {
        if !visibile {
            EmptyView()
                .frame(height: 0)
        } else {
            self
        }
    }
}


