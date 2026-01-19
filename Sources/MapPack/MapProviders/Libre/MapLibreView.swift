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
    @StateObject var viewModel: MapLibreWrapperModel
    var delegate: MLNMapViewDelegate
    var camera: MapCamera?
    var styleUrl: String?
    var inset: MapEdgeInsets?
    var trackingMode: MLNUserTrackingMode?
    var showsUserLocation: Bool = true
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        MLNMapViewWrapper(
            viewModel: viewModel,
            delegate: viewModel,
            camera: camera,
            styleUrl: viewModel.config?.lightStyle,
            inset: inset,
            trackingMode: trackingMode,
            showsUserLocation: showsUserLocation
        )
        .onChange(of: colorScheme) { newValue in
            viewModel.onChangeColorScheme(newValue)
        }
        .onAppear {
            viewModel.onChangeColorScheme(colorScheme)
        }
    }
}
