//
//  MapViewController.swift
//  Ildam
//
//  Created by applebro on 27/11/23.
//

import Foundation
import UIKit
import GoogleMaps

public struct GMapStatics {
    public static let viewAngle: CGFloat = 0
    @MainActor public static var pickerShift: CGFloat = 50
}

public class GoogleMapViewController: UIViewController {
    private var options: GoogleMaps.GMSMapViewOptions
    lazy var map: GMSMapView = {
        Logging.l("GMaps \(GMSServices.sdkLongVersion())")
        return GMSMapView.init(options: options)
    }()
    
    var isAnimating: Bool = false
    
    weak var delegate: GMSMapViewDelegate? {
        didSet {
            map.delegate = delegate
        }
    }
    
    public init(option: GoogleMaps.GMSMapViewOptions) {
        self.options = option
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func loadView() {
        super.loadView()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        self.view.addSubview(map)
        
        map.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleTopMargin, .flexibleBottomMargin]
        
        map.animate(toViewingAngle: GMapStatics.viewAngle)
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }
    
    open func focus(toLocation location: CLLocation) {
        map.animate(toLocation: location.coordinate)
        map.animate(toViewingAngle: GMapStatics.viewAngle)
    }
    
    open func setShowsMyCurrentLocation(to value: Bool) {
        map.isMyLocationEnabled = value
    }
}

public extension GMSMapView {
    var locationAtCenter: CLLocation {
        // Account for both top and bottom padding to find the true visual center
        // If top padding > bottom padding, center shifts up
        // If bottom padding > top padding, center shifts down
        let paddingOffset = self.padding.bottom / 2
        let safeAreaOffset = UIApplication.shared.safeArea.top / 2 - UIApplication.shared.safeArea.bottom / 2
        
        let visualCenter = CGPoint(
            x: self.bounds.midX,
            y: self.bounds.midY - paddingOffset + GMapStatics.pickerShift / 2 + safeAreaOffset
        )
        
        let coordinate = self.projection.coordinate(for: visualCenter)
        
        // Debug logs
        debugPrint("GMSMapView", "Map bounds: \(self.bounds)")
        debugPrint("GMSMapView", "Map padding: \(self.padding)")
        debugPrint("GMSMapView", "Padding offset: \(paddingOffset)")
        debugPrint("GMSMapView", "Visual center point: \(visualCenter)")
        debugPrint("GMSMapView", "Resulting coordinate: \(coordinate)")
        
        return CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }
}
