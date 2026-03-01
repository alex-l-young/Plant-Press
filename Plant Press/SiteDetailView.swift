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
    @State private var sortOption: SortOption = .byTime
    enum SortOption { case byTime }
    
    @State private var showingEditSiteSheet = false
    @State private var showingAddChecklistSheet = false
    
    // Export State
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    @State private var isExporting = false
    @State private var showingExportOptions = false
    
    // FIXED: Now sorts and displays Checklists instead of flattened observations
    var sortedChecklists: [Checklist] {
        return site.checklists.sorted { $0.creationDate > $1.creationDate }
    }
    
    var body: some View {
        ZStack {
            List {
                if sortedChecklists.isEmpty {
                    ContentUnavailableView(
                        "No Checklists Yet",
                        systemImage: "list.clipboard",
                        description: Text("Tap the + button to create your first checklist for this site.")
                    )
                } else {
                    ForEach(sortedChecklists) { checklist in
                        // Drill down into the specific checklist
                        NavigationLink(destination: ChecklistDetailView(checklist: checklist)) {
                            VStack(alignment: .leading) {
                                Text(checklist.creationDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.headline)
                                Text("\(checklist.observations.count) observations")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteChecklists)
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
                    
                    // 3. THE PRIMARY ACTION: Creates a Checklist
                    Button(action: { showingAddChecklistSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.accentColor)
                    }
                    
                    // 4. Map Button
                    NavigationLink(destination: SiteMapView(site: site)) {
                        Image(systemName: "map")
                    }
                    
                    // 5. Sort Menu
                    Menu {
                        Button("Most Recent") { sortOption = .byTime }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $showingEditSiteSheet) {
                SiteCreationView(siteToEdit: site)
            }
            .sheet(isPresented: $showingAddChecklistSheet) {
                // Passes the current site down to auto-populate the selection
                ChecklistCreationView(preselectedSite: site)
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
    
    private func deleteChecklists(at offsets: IndexSet) {
        for index in offsets {
            let checklist = sortedChecklists[index]
            site.modelContext?.delete(checklist)
        }
    }
    
    private func startExport(includePhotos: Bool) {
        isExporting = true
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            exportURL = ExportManager.createExport(from: site.checklists, includePhotos: includePhotos)
            isExporting = false
            showingShareSheet = true
        }
    }
}

// Keep this here so ChecklistDetailView can access it!
struct SpeciesGroup: Identifiable {
    let id: String
    let genus: String
    let species: String
    let count: Int
    let observations: [PlantObservation]
    let latestDate: Date
}
