//
//  SiteMapView.swift
//  Plant Press
//
//  Created by Alex Young.
//
//  DESCRIPTION:
//  This view displays a full-screen interactive map for a specific Site or Checklist.
//  It plots all associated plant observations as markers, shows the user's current
//  location, and allows the user to toggle satellite imagery.
//  The camera can dynamically jump between the user's current GPS location and the
//  optimal bounding box that frames all the plant observations. Tapping a marker
//  reveals a popup card to navigate directly to that observation's details.
//

import SwiftUI
import MapKit
import SwiftData

struct SiteMapView: View {
    var site: Site
    var checklist: Checklist? = nil
    
    @State private var selectedObservation: PlantObservation?
    @State private var isSatelliteView = false
    
    // NEW: We now permanently store the original calculation so we can return to it later!
    private let siteCameraPosition: MapCameraPosition
    
    @State private var position: MapCameraPosition
    
    var allObservations: [PlantObservation] {
        if let checklist = checklist {
            return checklist.observations
        }
        return site.checklists.flatMap { $0.observations }
    }
    
    init(site: Site, checklist: Checklist? = nil, initialSelection: PlantObservation? = nil) {
        self.site = site
        self.checklist = checklist
        _selectedObservation = State(initialValue: initialSelection)
        
        let obsToFrame = checklist != nil ? checklist!.observations : site.checklists.flatMap { $0.observations }
        let validObs = obsToFrame.filter { $0.latitude != nil && $0.longitude != nil }
        
        // We calculate the camera position locally first...
        let initialCamera: MapCameraPosition
        
        if let selection = initialSelection, let lat = selection.latitude, let lon = selection.longitude {
            initialCamera = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lon), span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
        } else if !validObs.isEmpty {
            let minLat = validObs.map { $0.latitude! }.min()!
            let maxLat = validObs.map { $0.latitude! }.max()!
            let minLon = validObs.map { $0.longitude! }.min()!
            let maxLon = validObs.map { $0.longitude! }.max()!
            
            let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
            let span = MKCoordinateSpan(latitudeDelta: max((maxLat - minLat) * 1.5, 0.005), longitudeDelta: max((maxLon - minLon) * 1.5, 0.005))
            initialCamera = .region(MKCoordinateRegion(center: center, span: span))
        } else if let lat = site.latitude, let lon = site.longitude {
            initialCamera = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lon), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
        } else {
            initialCamera = .automatic
        }
        
        // ...and then save it to BOTH the permanent constant and the active state variable!
        self.siteCameraPosition = initialCamera
        self._position = State(initialValue: initialCamera)
    }
    
    var body: some View {
        Map(position: $position, selection: $selectedObservation) {
            
            UserAnnotation()
            
            ForEach(allObservations) { obs in
                if let lat = obs.latitude, let lon = obs.longitude {
                    Marker("\(obs.genus) \(obs.species)", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                        .tag(obs)
                }
            }
        }
        .mapStyle(isSatelliteView ? .imagery : .standard)
        .overlay(alignment: .bottomTrailing) {
            VStack(spacing: 12) {
                
                // 1. NEW: Zoom back to the Site/Plants
                Button(action: {
                    withAnimation {
                        // Re-applies the original camera box we saved during init()
                        position = siteCameraPosition
                    }
                }) {
                    Image(systemName: "flag.fill")
                        .padding(10)
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                        .foregroundColor(.green)
                        .shadow(radius: 4)
                }
                
                // 2. Zoom to User Button
                Button(action: {
                    withAnimation {
                        position = .userLocation(fallback: .automatic)
                    }
                }) {
                    Image(systemName: "location.fill")
                        .padding(10)
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                        .foregroundColor(.accentColor)
                        .shadow(radius: 4)
                }
                
                // 3. Satellite Toggle Button
                Button(action: {
                    isSatelliteView.toggle()
                }) {
                    Image(systemName: isSatelliteView ? "map.fill" : "globe.americas.fill")
                        .padding(10)
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                        .foregroundColor(.primary)
                        .shadow(radius: 4)
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            if let obs = selectedObservation {
                NavigationLink(destination: ObservationDetailView(observation: obs)) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(obs.genus) \(obs.species)")
                                .font(.headline)
                                .italic()
                            Text(obs.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding()
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(checklist != nil ? "Checklist Map" : "\(site.name) Map")
        .navigationBarTitleDisplayMode(.inline)
    }
}
