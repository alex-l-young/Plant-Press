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
                        Button(action: {
                            isSatelliteView.toggle()
                        }) {
                            Image(systemName: isSatelliteView ? "map.fill" : "globe.americas.fill")
                                .padding()
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        
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
                        
                        // FIXED: Location Button
                        Button(action: {
                            // 1. If we already know the user's location, instantly snap the camera and move the pin
                            if let userLoc = locationManager.userLocation {
                                withAnimation {
                                    cameraPosition = .region(MKCoordinateRegion(center: userLoc, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
                                }
                                localPinLocation = userLoc
                            }
                            
                            // 2. Always request a fresh GPS update in case they've walked away
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
                
                if let pin = pinLocation {
                    cameraPosition = .region(MKCoordinateRegion(center: pin, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
                } else {
                    locationManager.requestPermission()
                    locationManager.requestLocation()
                }
            }
            .onChange(of: locationManager.userLocation) { oldLocation, newLocation in
                // We keep this purely to handle the very first launch when the app gets GPS for the first time
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
