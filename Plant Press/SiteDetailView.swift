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
    
    @State private var sortOption: SortOption = .byTime
    enum SortOption { case byTime }
    
    @State private var showingEditSiteSheet = false
    @State private var showingAddChecklistSheet = false
    
    // Export & Sort States
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    @State private var isExporting = false
    @State private var showingExportOptions = false
    @State private var showingSortOptions = false // NEW
    
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
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack {
                        // 1. Atlas
                        Link(destination: URL(string: "https://newyork.plantatlas.usf.edu")!) {
                            ToolbarIconView(icon: "safari", text: "Atlas")
                        }
                        Spacer()
                        
                        // 2. Export Button
                        Button(action: { showingExportOptions = true }) {
                            ToolbarIconView(icon: "square.and.arrow.up", text: "Export")
                        }
                        .confirmationDialog("Export Options", isPresented: $showingExportOptions, titleVisibility: .visible) {
                            Button("Export Data Only (CSV)") { startExport(includePhotos: false) }
                            Button("Export Data + Photos (Folder)") { startExport(includePhotos: true) }
                            Button("Cancel", role: .cancel) {}
                        }
                        
                        Spacer()
                        
                        // 3. Add List Button
                        Button(action: { showingAddChecklistSheet = true }) {
                            ToolbarIconView(icon: "plus.circle.fill", text: "New List", isProminent: true)
                        }
                        .offset(y: -4)
                        
                        Spacer()
                        
                        // 4. Map Button
                        NavigationLink(destination: SiteMapView(site: site)) {
                            ToolbarIconView(icon: "map", text: "Map")
                        }
                        
                        Spacer()
                        
                        // 5. Sort Button
                        Button(action: { showingSortOptions = true }) {
                            ToolbarIconView(icon: "arrow.up.arrow.down", text: "Sort")
                        }
                        .confirmationDialog("Sort By", isPresented: $showingSortOptions, titleVisibility: .visible) {
                            Button("Most Recent") { sortOption = .byTime }
                            Button("Cancel", role: .cancel) {}
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                }
                .background(.regularMaterial)
            }
            .sheet(isPresented: $showingEditSiteSheet) {
                SiteCreationView(siteToEdit: site)
            }
            .sheet(isPresented: $showingAddChecklistSheet) {
                ChecklistCreationView(preselectedSite: site)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            
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
