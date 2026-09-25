//
//  File.swift
//  IMap
//
//  Created by applebro on 22/06/26.
//

import Foundation
import CoreLocation

// MARK: - MapInteractionDelegate Implementation
extension UniversalMapViewModel: MapInteractionDelegate {
    public func mapDidStartDragging() {
        cancelUserTrackingForInteraction()
        clearAddressInfoAfterViewUpdate()
        self.delegate?.mapDidStartDragging(map: self.mapProviderInstance)
    }
    
    public func mapDidStartMoving() {
        clearAddressInfoAfterViewUpdate()
        self.delegate?.mapDidStartMoving(map: self.mapProviderInstance)
    }
    
    public func mapDidEndDragging(at location: CLLocation) {
        self.delegate?.mapDidEndDragging(map: self.mapProviderInstance, at: location)
    }
    
    public func mapDidTapMarker(id: String) -> Bool {
        self.delegate?.mapDidTapMarker(map: self.mapProviderInstance, id: id) ?? false
    }
    
    public func mapDidTap(at coordinate: CLLocationCoordinate2D) {
        self.delegate?.mapDidTap(map: self.mapProviderInstance, at: coordinate)
    }
    
    public func mapDidLoaded() {
        self.delegate?.mapDidLoaded(map: self.mapProviderInstance)
    }
    
    public func mapDidRotate(to coordinate: CLLocationCoordinate2D) {
        self.delegate?.mapDidRotate(map: self.mapProviderInstance, location: coordinate)
    }

    /// Map SDK delegates can synchronously report camera movement while SwiftUI is
    /// updating a representable. Defer published state changes until that update ends.
    private func clearAddressInfoAfterViewUpdate() {
        Task { @MainActor [weak self] in
            self?.addressInfo = nil
        }
    }
}
