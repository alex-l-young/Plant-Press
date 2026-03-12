import SwiftUI
import MapKit
import UIKit // Required for UIPasteboard (copy to clipboard)

struct ObservationDetailView: View {
    var observation: PlantObservation
    
    @State private var showingEditSheet = false
    @State private var fullScreenImageItem: ImageItem?
    
    // Tracks if the coordinates were just copied to show the checkmark
    @State private var copiedToClipboard = false
    
    var body: some View {
        List {
            Section("Taxonomy") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(observation.genus) \(observation.species)")
                        .font(.title2)
                        .italic()
                        .bold()
                    
                    if let infra = observation.infraspecificName {
                        Text("\(observation.isVariety ? "var." : "ssp.") \(infra)")
                            .font(.headline)
                            .italic()
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            
            if let lat = observation.latitude, let lon = observation.longitude, let site = observation.checklist?.site {
                Section("Location") {
                    // ROW 1: The Map (Navigates to full map)
                    NavigationLink(destination: SiteMapView(site: site, initialSelection: observation)) {
                        Map(bounds: MapCameraBounds(minimumDistance: 500, maximumDistance: 500)) {
                            Marker("Current", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                        }
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .allowsHitTesting(false)
                        .padding(.vertical, 4)
                    }
                    
                    // ROW 2: The Coordinate Box (Copies to clipboard)
                    Button(action: {
                        // FIXED: Format the coordinates to 6 decimal places for the clipboard
                        UIPasteboard.general.string = String(format: "%.6f, %.6f", lat, lon)
                        
                        // Trigger the checkmark animation
                        withAnimation {
                            copiedToClipboard = true
                        }
                        
                        // Reset the icon back to a clipboard after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                copiedToClipboard = false
                            }
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Coordinates")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                // FIXED: Updated the visual text to also show 6 decimal places for consistency
                                Text("\(String(format: "%.6f", lat)), \(String(format: "%.6f", lon))")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            // Dynamically swaps the icon and color based on the state
                            Image(systemName: copiedToClipboard ? "checkmark.circle.fill" : "doc.on.clipboard")
                                .foregroundColor(copiedToClipboard ? .green : .accentColor)
                                .font(.title3)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            if !observation.photoData.isEmpty {
                Section("Photos") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(observation.photoData, id: \.self) { data in
                                if let uiImage = UIImage(data: data) {
                                    Button(action: {
                                        fullScreenImageItem = ImageItem(image: uiImage)
                                    }) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            if !observation.notes.isEmpty {
                Section("Notes") {
                    Text(observation.notes)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Section("Metadata") {
                HStack {
                    Text("Recorded On")
                    Spacer()
                    Text(observation.timestamp.formatted(date: .long, time: .shortened))
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Observation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let checklist = observation.checklist {
                ObservationCreationView(checklist: checklist, observationToEdit: observation)
            }
        }
        .fullScreenCover(item: $fullScreenImageItem) { item in
            FullScreenImageView(image: item.image)
        }
    }
}

struct ImageItem: Identifiable {
    let id = UUID()
    let image: UIImage
}
