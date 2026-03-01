//
//  ChecklistDetailView.swift
//  Plant Press
//
//  Created by Alex Young on 2/28/26.
//

import SwiftUI
import SwiftData

struct ChecklistDetailView: View {
    @Bindable var checklist: Checklist
    
    // Sorting State
    @State private var sortOption: SortOption = .alphabetical
    enum SortOption { case alphabetical, byTime }
    
    @State private var showingEditChecklistSheet = false
    @State private var showingAddObservationSheet = false
    
    // Export State
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    @State private var isExporting = false
    @State private var showingExportOptions = false
    
    var groupedObservations: [SpeciesGroup] {
        let dictionary = Dictionary(grouping: checklist.observations) { "\($0.genus)_\($0.species)" }
        
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
        ZStack {
            List {
                if groupedObservations.isEmpty {
                    ContentUnavailableView(
                        "No Plants Yet",
                        systemImage: "leaf",
                        description: Text("Tap the + button to add your first observation.")
                    )
                } else {
                    ForEach(groupedObservations) { group in
                        // NOTE: ObservationListView will need to be updated to accept a checklist!
                        NavigationLink(destination: ObservationListView(
                            checklist: checklist,
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
            // Use the date as the title, and the site name as the subtitle
            .navigationTitle(checklist.creationDate.formatted(date: .abbreviated, time: .shortened))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    // 1. Safari Link
                    Link(destination: URL(string: "https://newyork.plantatlas.usf.edu")!) {
                        Image(systemName: "safari")
                    }
                    
                    // 2. Export Button
                    Button(action: { showingExportOptions = true }) {
                        Image(systemName: "square.and.arrow.up")
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
                    
                    // 3. THE PRIMARY ACTION
                    Button(action: { showingAddObservationSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.accentColor)
                    }
                    
                    // 4. Map Button (Passes the site associated with this checklist)
                    if let site = checklist.site {
                        NavigationLink(destination: SiteMapView(site: site)) {
                            Image(systemName: "map")
                        }
                    } else {
                        Spacer() // Placeholder if no site exists
                    }
                    
                    // 5. Sort Menu
                    Menu {
                        Button("Time Created") { sortOption = .byTime }
                        Button("Alphabetical") { sortOption = .alphabetical }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $showingEditChecklistSheet) {
                // NOTE: ChecklistCreationView will need a checklistToEdit property to support editing
                ChecklistCreationView(checklistToEdit: checklist)
            }
            .sheet(isPresented: $showingAddObservationSheet) {
                // NOTE: ObservationCreationView needs to accept a checklist instead of a site
                ObservationCreationView(checklist: checklist)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            
            // The Loading Overlay
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
                checklist.modelContext?.delete(observation)
            }
        }
    }
    
    private func startExport(includePhotos: Bool) {
        isExporting = true
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            exportURL = ExportManager.createExport(from: [checklist], includePhotos: includePhotos)
            isExporting = false
            showingShareSheet = true
        }
    }
}
