//
//  SiteDetailView.swift
//  Trillium
//
//  Created by Alex Young on 2/24/26.
//

import SwiftUI
import SwiftData

struct SiteDetailView: View {
    @Bindable var site: Site
    
    // Sorting State
    @State private var sortOption: SortOption = .alphabetical
    enum SortOption { case alphabetical, byTime }
    
    @State private var showingEditSiteSheet = false
    @State private var showingAddObservationSheet = false
    
    // Export State
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    @State private var isExporting = false // NEW
    @State private var showingExportOptions = false // NEW
    
    var groupedObservations: [SpeciesGroup] {
        let dictionary = Dictionary(grouping: site.observations) { "\($0.genus)_\($0.species)" }
        
        let groups = dictionary.map { key, observations in
            let first = observations.first!
            let latestDate = observations.max(by: { $0.timestamp < $1.timestamp })?.timestamp ?? Date.distantPast
            
            return SpeciesGroup(
                id: key,
                genus: first.genus,
                species: first.species,
                count: observations.count,
                observations: observations,
                latestDate: latestDate
            )
        }
        
        switch sortOption {
        case .alphabetical:
            return groups.sorted { $0.genus == $1.genus ? $0.species < $1.species : $0.genus < $1.genus }
        case .byTime:
            return groups.sorted { $0.latestDate > $1.latestDate }
        }
    }
    
    var body: some View {
        ZStack { // NEW: ZStack wrapper
            List {
                if groupedObservations.isEmpty {
                    ContentUnavailableView(
                        "No Plants Yet",
                        systemImage: "leaf",
                        description: Text("Tap the + button to add your first observation.")
                    )
                } else {
                    ForEach(groupedObservations) { group in
                        NavigationLink(destination: ObservationListView(
                            site: site,
                            genus: group.genus,
                            species: group.species
                        )) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(group.genus) \(group.species)")
                                        .font(.headline)
                                        .italic()
                                }
                                Spacer()
                                Text("\(group.count)")
                                    .font(.subheadline)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .onDelete(perform: deleteSpeciesGroup)
                }
            }
            .navigationTitle(site.name)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit Site") {
                        showingEditSiteSheet = true
                    }
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    Link(destination: URL(string: "https://newyork.plantatlas.usf.edu")!) {
                        Image(systemName: "safari")
                    }
                    
                    Spacer()
                    
                    // UPDATED: Export Button
                    Button(action: { showingExportOptions = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: SiteMapView(site: site)) {
                        Image(systemName: "map")
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button("Alphabetical") { sortOption = .alphabetical }
                        Button("Most Recent") { sortOption = .byTime }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    
                    Spacer()
                    
                    Button(action: { showingAddObservationSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingEditSiteSheet) {
                SiteCreationView(siteToEdit: site)
            }
            .sheet(isPresented: $showingAddObservationSheet) {
                ObservationCreationView(site: site)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .confirmationDialog("Export Options", isPresented: $showingExportOptions, titleVisibility: .visible) {
                Button("Export Data Only (CSV)") {
                    startExport(includePhotos: false)
                }
                Button("Export Data + Photos (Folder)") {
                    startExport(includePhotos: true)
                }
                Button("Cancel", role: .cancel) {}
            }
            
            // NEW: The Loading Overlay
            if isExporting {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Generating CSV...")
                        .foregroundColor(.white)
                        .bold()
                }
                .padding(40)
                .background(Color.gray.opacity(0.8))
                .cornerRadius(16)
            }
        }
    }
    
    private func deleteSpeciesGroup(at offsets: IndexSet) {
        for index in offsets {
            let group = groupedObservations[index]
            for observation in group.observations {
                site.modelContext?.delete(observation)
            }
        }
    }
    
    // NEW: Export Helper
    private func startExport(includePhotos: Bool) {
        isExporting = true
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            exportURL = ExportManager.createExport(from: [site], includePhotos: includePhotos)
            isExporting = false
            showingShareSheet = true
        }
    }
}

struct SpeciesGroup: Identifiable {
    let id: String
    let genus: String
    let species: String
    let count: Int
    let observations: [PlantObservation]
    let latestDate: Date
}
