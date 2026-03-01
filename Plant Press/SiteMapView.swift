import SwiftUI
import MapKit
import SwiftData

struct SiteMapView: View {
    var site: Site
    @State private var selectedObservation: PlantObservation?
    
    @State private var isSatelliteView = false
    
    // NEW: Dynamically gathers every observation across all checklists for this site
    var allObservations: [PlantObservation] {
        site.checklists.flatMap { $0.observations }
    }
    
    init(site: Site, initialSelection: PlantObservation? = nil) {
        self.site = site
        _selectedObservation = State(initialValue: initialSelection)
    }
    
    var body: some View {
        Map(selection: $selectedObservation) {
            // FIXED: Now loops through our flattened array of all plants
            ForEach(allObservations) { obs in
                if let lat = obs.latitude, let lon = obs.longitude {
                    Marker("\(obs.genus) \(obs.species)", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                        .tag(obs)
                }
            }
        }
        .mapStyle(isSatelliteView ? .imagery : .standard)
        .overlay(alignment: .bottomTrailing) {
            Button(action: {
                isSatelliteView.toggle()
            }) {
                Image(systemName: isSatelliteView ? "map.fill" : "globe.americas.fill")
                    .padding(10)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(radius: 4)
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
        .navigationTitle("\(site.name) Map")
        .navigationBarTitleDisplayMode(.inline)
    }
}
