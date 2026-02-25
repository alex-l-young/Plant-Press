//
//  LocationManager.swift
//  Trillium
//
//  Created by Alex Young on 2/24/26.
//

import Foundation
import CoreLocation
internal import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    // Publishes the location so our Views can see it
    @Published var userLocation: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // Critical for field work
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // The button will call this
    func requestLocation() {
        locationManager.requestLocation()
    }
    
    // Delegate method: Success
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
        }
    }
    
    // Delegate method: Failure (Required)
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

// Teaches Swift how to compare two coordinates for the .onChange modifier
extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
