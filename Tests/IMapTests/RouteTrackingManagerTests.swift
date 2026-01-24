import XCTest
import CoreLocation
@testable import MapPack

final class RouteTrackingManagerTests: XCTestCase {
    
    func testDriverOnTrack() {
        // Create a simple straight line route: (0,0) -> (0, 0.001) ~111m long
        let start = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let end = CLLocationCoordinate2D(latitude: 0, longitude: 0.001)
        let coordinates = [start, end]
        
        let manager = RouteTrackingManager(routeCoordinates: coordinates, threshold: 30)
        
        // Driver at (0, 0.0005) - exactly midpoint
        let driverLoc = CLLocationCoordinate2D(latitude: 0, longitude: 0.0005)
        
        let status = manager.updateDriverLocation(driverLoc)
        
        if case .onTrack(let snapped, let remainingPath) = status {
            // Should be exactly at driverLoc since it's on the line
            XCTAssertEqual(snapped.latitude, 0, accuracy: 0.000001)
            XCTAssertEqual(snapped.longitude, 0.0005, accuracy: 0.000001)
            
            // Remaining path should start at snapped point
            XCTAssertEqual(remainingPath.first?.latitude, 0, accuracy: 0.000001)
            XCTAssertEqual(remainingPath.first?.longitude, 0.0005, accuracy: 0.000001)
            XCTAssertEqual(remainingPath.last?.latitude, 0, accuracy: 0.000001)
            XCTAssertEqual(remainingPath.last?.longitude, 0.001, accuracy: 0.000001)
        } else {
            XCTFail("Expected onTrack")
        }
    }
    
    func testDriverSlightlyOffTrackCaptured() {
        // Route: (0,0) -> (0, 0.001)
        let start = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let end = CLLocationCoordinate2D(latitude: 0, longitude: 0.001)
        let coordinates = [start, end]
        
        let manager = RouteTrackingManager(routeCoordinates: coordinates, threshold: 30)
        
        // Driver at (0.0001, 0.0005). 
        // 1 degree lat ~ 111km. 0.0001 ~ 11 meters.
        // Should be within 30m threshold.
        // Snapped point should be (0, 0.0005)
        let driverLoc = CLLocationCoordinate2D(latitude: 0.0001, longitude: 0.0005)
        
        let status = manager.updateDriverLocation(driverLoc)
        
        if case .onTrack(let snapped, _) = status {
            XCTAssertEqual(snapped.latitude, 0, accuracy: 0.000001)
            XCTAssertEqual(snapped.longitude, 0.0005, accuracy: 0.000001)
        } else {
            XCTFail("Expected onTrack")
        }
    }
    
    func testDriverOutOfRoute() {
        // Route: (0,0) -> (0, 0.001)
        let start = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let end = CLLocationCoordinate2D(latitude: 0, longitude: 0.001)
        let coordinates = [start, end]
        
        let manager = RouteTrackingManager(routeCoordinates: coordinates, threshold: 30)
        
        // Driver at (0.001, 0.0005) -> ~111 meters away.
        // Threshold 30m. Should be out.
        let driverLoc = CLLocationCoordinate2D(latitude: 0.001, longitude: 0.0005)
        
        let status = manager.updateDriverLocation(driverLoc)
        
        if case .outOfRoute = status {
            // Success
        } else {
            XCTFail("Expected outOfRoute")
        }
    }
}