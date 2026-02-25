//
//  ContentView.swift
//  Trillium
//
//  Created by Alex Young on 2/24/26.
//
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sites: [Site]
    
    @State private var showingAddSiteSheet = false
    @State private var sortOption: SortOption = .byTimeCreated
    
    // Export & Loading State
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    @State private var isExporting = false
    @State private var showingExportOptions = false
    
    enum SortOption {
        case alphabetical
        case byTimeCreated
    }
    
    var sortedSites: [Site] {
        switch sortOption {
        case .alphabetical:
            return sites.sorted { $0.name < $1.name }
        case .byTimeCreated:
            return sites.sorted { $0.creationDate > $1.creationDate }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack { // NEW: ZStack allows us to float the spinner on top
                List {
                    ForEach(sortedSites) { site in
                        NavigationLink(destination: SiteDetailView(site: site)) {
                            HStack {
                                if let data = site.thumbnailData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    Image(systemName: "leaf.circle.fill")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.green)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(site.name)
                                        .font(.headline)
                                    Text(site.creationDate.formatted(date: .abbreviated, time: .shortened))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .navigationTitle("My Sites")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showingAddSiteSheet = true }) {
                            Label("Add Site", systemImage: "plus")
                        }
                    }
                    
                    ToolbarItemGroup(placement: .bottomBar) {
                    Button(action: { showingExportOptions = true }) { // UPDATED
                            Image(systemName: "square.and.arrow.up")
                            Text("Export")
                        }
                        
                        Spacer()
                        
                        Menu {
                            Button("Time Created") { sortOption = .byTimeCreated }
                            Button("Alphabetical") { sortOption = .alphabetical }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                            Text("Sort")
                        }
                    }
                }
                .sheet(isPresented: $showingAddSiteSheet) {
                    SiteCreationView()
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
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let siteToDelete = sortedSites[index]
                modelContext.delete(siteToDelete)
            }
        }
    }
    
    // UPDATED: Now accepts the user's choice and passes it to the manager
    private func startExport(includePhotos: Bool) {
        isExporting = true
        
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            exportURL = ExportManager.createExport(from: sites, includePhotos: includePhotos)
            
            isExporting = false
            showingShareSheet = true
        }
    }
}
