import SwiftUI
import MapKit

struct ObservationDetailView: View {
    var observation: PlantObservation
    
    @State private var showingEditSheet = false
    
    // UPDATED: We only need one state variable now using our new wrapper
    @State private var fullScreenImageItem: ImageItem?
    
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
            
            if let lat = observation.latitude, let lon = observation.longitude, let site = observation.site {
                Section("Location") {
                    NavigationLink(destination: SiteMapView(site: site, initialSelection: observation)) {
                        VStack(alignment: .leading) {
                            Map(bounds: MapCameraBounds(minimumDistance: 500, maximumDistance: 500)) {
                                Marker("Current", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                            }
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .allowsHitTesting(false)
                            
                            Text("Lat: \(String(format: "%.5f", lat)), Lon: \(String(format: "%.5f", lon))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                }
            }
            
            if !observation.photoData.isEmpty {
                Section("Photos") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(observation.photoData, id: \.self) { data in
                                if let uiImage = UIImage(data: data) {
                                    // UPDATED: Simply wrap the image and pass it to the state
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
            if let site = observation.site {
                ObservationCreationView(site: site, observationToEdit: observation)
            }
        }
        // UPDATED: This guarantees the view only opens when the image is fully loaded
        .fullScreenCover(item: $fullScreenImageItem) { item in
            FullScreenImageView(image: item.image)
        }
    }
}

// NEW: This tiny wrapper allows SwiftUI to uniquely identify the image being passed
struct ImageItem: Identifiable {
    let id = UUID()
    let image: UIImage
}
