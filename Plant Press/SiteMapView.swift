import SwiftUI
import MapKit
import SwiftData

struct SiteMapView: View {
    var site: Site
    // NEW: Optional checklist to filter the map
    var checklist: Checklist? = nil
    
    @State private var selectedObservation: PlantObservation?
    @State private var isSatelliteView = false
    
    // UPDATED: Return only the checklist's observations if one was passed in
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
    }
    
    var body: some View {
        Map(selection: $selectedObservation) {
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
        // UPDATED: Dynamic title changes depending on what we are viewing
        .navigationTitle(checklist != nil ? "Checklist Map" : "\(site.name) Map")
        .navigationBarTitleDisplayMode(.inline)
    }
}
