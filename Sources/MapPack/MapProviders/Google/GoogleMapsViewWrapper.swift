//
//  GMapsViewWrapper.swift
//  Ildam
//
//  Created by applebro on 27/11/23.
//

import Foundation
import GoogleMaps
import SwiftUI

public struct GMapCamera {
    public var camera: GMSCameraPosition?
    public var cameraUpdate: GMSCameraUpdate?
    public var animate: Bool
    
    public init(camera: GMSCameraPosition? = nil, cameraUpdate: GMSCameraUpdate?, animate: Bool) {
        self.camera = camera
        self.cameraUpdate = cameraUpdate
        self.animate = animate
    }
}

public struct GoogleMapsViewWrapper: UIViewControllerRepresentable, @unchecked Sendable {
    public typealias MarkerView = (_ mapView: GMSMapView, _ marker: GMSMarker) -> UIView?
    @ObservedObject var viewModel: GoogleMapsViewWrapperModel
    var options: GMSMapViewOptions

    public init(viewModel: GoogleMapsViewWrapperModel, options: GMSMapViewOptions) {
        self.viewModel = viewModel
        self.options = options
    }

    public func makeUIViewController(context: Context) -> GoogleMapViewController {
        let vc = GoogleMapViewController(option: options)
        vc.delegate = viewModel
        vc.map.isBuildingsEnabled = false
        vc.map.isIndoorEnabled = false
        vc.map.isTrafficEnabled = false
        vc.map.settings.allowScrollGesturesDuringRotateOrZoom = false
        vc.map.settings.rotateGestures = true
        vc.map.settings.tiltGestures = false
        
        viewModel.set(map: vc.map)
        return vc
    }
    
    public func updateUIViewController(_ uiViewController: GoogleMapViewController, context: Context) {

    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    public class Coordinator: NSObject, @unchecked Sendable {
        var parent: GoogleMapsViewWrapper

        init(parent: GoogleMapsViewWrapper) {
            self.parent = parent
        }
    }
}

public extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension UIImage {
    @MainActor
    static func systemImageFilled(symbolName: String, color: UIColor, size: CGSize = CGSize(width: 30, height: 30)) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: size.width, weight: .regular)
        guard let symbolImage = UIImage(systemName: symbolName, withConfiguration: config) else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            color.set()
            symbolImage.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
