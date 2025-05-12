//
//  GoogleMapsView.swift
//  UniversalMap
//
//  Created by Muhammadjon Tohirov on 08/05/25.
//

// UniversalMap/Providers/GoogleMaps/GoogleMapView.swift
import Foundation
import SwiftUI
import GoogleMaps

/// SwiftUI wrapper for Google Maps
struct GoogleMapView: View {
    var viewModel: GoogleMapsViewWrapperModel
    var options: GMSMapViewOptions
    
    var body: some View {
        GoogleMapsViewWrapper(
            viewModel: viewModel,
            options: options
        )
    }
}
