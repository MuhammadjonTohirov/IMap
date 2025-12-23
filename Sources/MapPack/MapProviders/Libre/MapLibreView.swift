//
//  File.swift
//  IMap
//
//  Created by Muhammadjon Tohirov on 23/12/25.
//

import Foundation
import SwiftUI
import MapLibre

/// SwiftUI wrapper for Google Maps
struct MapLibreMapView: View {
    var viewModel: MapLibreWrapperModel
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        MapLibreMapView(viewModel: viewModel)
        .onChange(of: colorScheme) { newValue in
            viewModel.onChangeColorScheme(newValue)
        }
        .onAppear {
            viewModel.onChangeColorScheme(colorScheme)
        }
    }
}
