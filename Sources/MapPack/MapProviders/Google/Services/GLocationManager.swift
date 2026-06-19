//
//  LocationManager+Extensions.swift
//  IMap
//
//  Created by Muhammadjon Tohirov on 03/03/25.
//

import Foundation
import GoogleMaps

struct GLocationManager {
    public func getAddressFromLatLon(latitude: Double, longitude: Double, completion: @escaping (String) -> Void) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        GMSGeocoder().reverseGeocodeCoordinate(location.coordinate) { response, error in
            guard let address = response?.firstResult(), let lines = address.lines else {
                return
            }
            
            let fullAddress = lines.joined(separator: ", ")
            completion(fullAddress)
        }
    }
}
