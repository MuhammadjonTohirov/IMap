//
//  File.swift
//  IMap
//
//  Created by applebro on 18/06/26.
//

import Foundation
import UIKit
import MapLibre

class UniversalUserLocationAnnotationView: MLNUserLocationAnnotationView {
    private let circleView = UIView()
    private var iconView: UIImageView?
    private var iconSize: CGSize = .zero
    
    private var lastAccuracy: CLLocationAccuracy = 0
    private var lastLatitude: CLLocationDegrees = 0
    private var isCircleHidden: Bool = true
    private var displayRotation: CLLocationDirection = 0
    
    override init(annotation: MLNAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        clipsToBounds = false
        circleView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        circleView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.6).cgColor
        circleView.layer.borderWidth = 1
        circleView.isUserInteractionEnabled = false
        addSubview(circleView)
        sendSubviewToBack(circleView)
    }
    
    func setup(image: UIImage, scale: CGFloat) {
        if iconView == nil {
            let iv = UIImageView(image: image)
            iv.contentMode = .scaleAspectFit
            addSubview(iv)
            iconView = iv
        } else {
            iconView?.image = image
        }
        
        self.iconSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        // Reset any rotation before frame math, then restore it afterwards.
        iconView?.transform = .identity
        iconView?.frame = CGRect(origin: .zero, size: iconSize)

        // Initial layout
        self.frame = iconView?.frame ?? .zero
        iconView?.center = CGPoint(x: frame.width/2, y: frame.height/2)
        applyRotation()
    }
    
    func setCircleHidden(_ hidden: Bool) {
        self.isCircleHidden = hidden
        self.circleView.isHidden = hidden
    }

    /// Rotates the icon to a display angle (degrees) already compensated for the current
    /// map bearing. The accuracy circle is left unrotated.
    func setDisplayRotation(_ degrees: CLLocationDirection) {
        self.displayRotation = degrees
        applyRotation()
    }

    private func applyRotation() {
        iconView?.transform = CGAffineTransform(rotationAngle: CGFloat(displayRotation * .pi / 180))
    }
    
    func update(accuracy: CLLocationAccuracy, zoom: Double, latitude: CLLocationDegrees) {
        self.lastAccuracy = accuracy
        self.lastLatitude = latitude
        updateLayout(zoom: zoom)
    }
    
    private func updateLayout(zoom: Double) {
        if isCircleHidden { return }
        
        // Calculate radius in points
        // metersPerPoint = 40075016.686 * cos(lat * pi / 180) / (256 * 2^zoom)
        // Simplified:
        let metersPerPoint = 156543.03392 * cos(lastLatitude * .pi / 180) / pow(2, zoom)
        let radiusPoints = CGFloat(lastAccuracy / metersPerPoint)
        
        // Diameter
        let diameter = radiusPoints * 2
        
        // We do NOT resize self.frame (the annotation view itself) to avoid flickering.
        // The view stays the size of the icon. The circle grows outside it (clipsToBounds = false).
        
        let center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let circleFrame = CGRect(
            x: center.x - diameter / 2,
            y: center.y - diameter / 2,
            width: diameter,
            height: diameter
        )
        
        if circleView.frame != circleFrame {
             circleView.frame = circleFrame
             circleView.layer.cornerRadius = diameter / 2
        }
    }
}
