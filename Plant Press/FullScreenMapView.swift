import SwiftUI
import MapKit

struct FullScreenMapView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var pinLocation: CLLocationCoordinate2D?
    var siteLocation: CLLocationCoordinate2D? = nil
    
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var localPinLocation: CLLocationCoordinate2D?
    
    @State private var isSatelliteView = false
    
    var body: some View {
        NavigationStack {
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    if let localPinLocation {
                        Marker("Selected Location", coordinate: localPinLocation)
                    }
                    if let siteLoc = siteLocation {
                        Marker("Site Origin", coordinate: siteLoc)
                            .tint(.purple)
                    }
                    UserAnnotation()
                }
                .mapStyle(isSatelliteView ? .imagery : .standard)
                .onTapGesture { position in
                    if let coordinate = proxy.convert(position, from: .local) {
                        localPinLocation = coordinate
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    VStack(spacing: 12) {
                        // 1. Layer Toggle
                        Button(action: {
                            isSatelliteView.toggle()
                        }) {
                            Image(systemName: isSatelliteView ? "map.fill" : "globe.americas.fill")
                                .padding()
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        
                        // 2. Zoom to Site Button
                        if let siteLoc = siteLocation {
                            Button(action: {
                                withAnimation {
                                    cameraPosition = .region(MKCoordinateRegion(center: siteLoc, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
                                }
                            }) {
                                Image(systemName: "flag.fill")
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                        }
                        
                        // 3. Zoom to User Button
                        Button(action: {
                            if let userLoc = locationManager.userLocation {
                                withAnimation {
                                    cameraPosition = .region(MKCoordinateRegion(center: userLoc, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
                                }
                                localPinLocation = userLoc
                            }
                            locationManager.requestPermission()
                            locationManager.requestLocation()
                        }) {
                            Image(systemName: "location.fill")
                                .padding()
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear Pin") {
                        localPinLocation = nil
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        pinLocation = localPinLocation
                        dismiss()
                    }
                }
            }
            .onAppear {
                localPinLocation = pinLocation
                
                // 1. If editing an existing pin, snap to it
                if let pin = pinLocation {
                    cameraPosition = .region(MKCoordinateRegion(center: pin, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
                } else {
                    // 2. FIXED: Otherwise, ALWAYS aggressively seek the user's location
                    locationManager.requestPermission()
                    locationManager.requestLocation()
                }
            }
            .onChange(of: locationManager.userLocation) { oldLocation, newLocation in
                // FIXED: Instantly zoom to the user the moment GPS is acquired (if no pin is set)
                if let newLocation, localPinLocation == nil {
                    withAnimation {
                        cameraPosition = .region(MKCoordinateRegion(center: newLocation, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
                    }
                    localPinLocation = newLocation
                }
            }
        }
    }
}

// Explicitly teaches Swift how to compare two coordinates so .onChange works
extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
