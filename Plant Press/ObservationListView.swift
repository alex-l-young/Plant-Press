//
//  ObservationListView.swift
//  Trillium
//
//  Created by Alex Young on 2/24/26.
//

import SwiftUI
import SwiftData

struct ObservationListView: View {
    @Environment(\.modelContext) private var modelContext
    
    // FIXED: Changed from Site to Checklist
    let checklist: Checklist
    let genus: String
    let species: String
    
    @State private var sortOption: SortOption = .byTimeCreated
    @State private var showingCreateSheet = false
    
    enum SortOption {
        case alphabetical
        case byTimeCreated
    }
    
    // Dynamically filter the checklist's observations for this specific species
    var filteredObservations: [PlantObservation] {
        // FIXED: Now filters from checklist.observations
        let all = checklist.observations.filter { $0.genus == genus && $0.species == species }
        
        switch sortOption {
        case .alphabetical:
            return all.sorted { ($0.infraspecificName ?? "") < ($1.infraspecificName ?? "") }
        case .byTimeCreated:
            return all.sorted { $0.timestamp > $1.timestamp }
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredObservations) { observation in
                // NOTE: ObservationDetailView will need to be updated next if it references a Site!
                NavigationLink(destination: ObservationDetailView(observation: observation)) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("\(observation.genus) \(observation.species)")
                                .italic()
                                .font(.headline)
                            
                            if let infra = observation.infraspecificName {
                                Text(observation.isVariety ? "var." : "ssp.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(infra)
                                    .italic()
                                    .font(.headline)
                            }
                        }
                        
                        // Timestamp & Coords
                        HStack {
                            Text(observation.timestamp.formatted(date: .abbreviated, time: .shortened))
                            Spacer()
                            if let lat = observation.latitude, let lon = observation.longitude {
                                Text("\(String(format: "%.4f", lat)), \(String(format: "%.4f", lon))")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                        
                        // Thumbnail Strip
                        if !observation.photoData.isEmpty {
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(observation.photoData.prefix(3), id: \.self) { data in
                                        if let img = UIImage(data: data) {
                                            Image(uiImage: img)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 40, height: 40)
                                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                        }
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain) // Keeps the list row clickable without blue highlighting
            }
            .onDelete(perform: deleteObservation)
        }
        .navigationTitle("\(genus) \(species)")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider() // Adds a crisp line separating the list from the bar
                
                HStack {
                    Spacer()
                    Button(action: { showingCreateSheet = true }) {
                        ToolbarIconView(icon: "plus.circle.fill", text: "Add Obs", isProminent: true)
                    }
                    // Bumps the big button up slightly to make it pop!
                    .offset(y: -4)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 5) // Extra padding for devices without home indicators
            }
            .background(.regularMaterial) // Gives it that native Apple blurred glass look
        }
        .sheet(isPresented: $showingCreateSheet) {
            // FIXED: Now passes the checklist down to the creation form instead of a site
            ObservationCreationView(checklist: checklist, initialGenus: genus, initialSpecies: species)
        }
    }
    
    private func deleteObservation(offsets: IndexSet) {
        for index in offsets {
            let obs = filteredObservations[index]
            modelContext.delete(obs)
        }
    }
}
