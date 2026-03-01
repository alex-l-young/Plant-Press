//
//  ContentView.swift
//  Trillium
//
//  Created by Alex Young on 2/24/26.
//
import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sites: [Site]
    @Query private var checklists: [Checklist]
    
    // Tab selection state
    enum TabSelection {
        case checklists
        case sites
    }
    @State private var selectedTab: TabSelection = .checklists
    
    @State private var showingAddSiteSheet = false
    @State private var showingAddChecklistSheet = false
    
    @State private var sortOption: SortOption = .byTimeCreated
    @State private var showingSortOptions = false
    
    // Export & Loading State
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    @State private var isExporting = false
    @State private var showingExportOptions = false
    @State private var showingAbout = false
    
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
    
    var sortedChecklists: [Checklist] {
        switch sortOption {
        case .alphabetical:
            return checklists.sorted { ($0.site?.name ?? "") < ($1.site?.name ?? "") }
        case .byTimeCreated:
            return checklists.sorted { $0.creationDate > $1.creationDate }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View Selection", selection: $selectedTab) {
                    Text("Checklists").tag(TabSelection.checklists)
                    Text("Sites").tag(TabSelection.sites)
                }
                .pickerStyle(.segmented)
                .padding()
                
                ZStack {
                    List {
                        if selectedTab == .sites {
                            // --- SITES LIST ---
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
                                            // FIXED: Added the checklist count subheader
                                            Text("\(site.checklists.count) checklist\(site.checklists.count == 1 ? "" : "s")")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            .onDelete(perform: deleteSites)
                            
                        } else {
                            // --- CHECKLISTS LIST ---
                            ForEach(sortedChecklists) { checklist in
                                NavigationLink(destination: ChecklistDetailView(checklist: checklist)) {
                                    // FIXED: Wrapped in an HStack to push the badge to the right
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(checklist.creationDate.formatted(date: .abbreviated, time: .shortened))
                                                .font(.headline)
                                            
                                            Text(checklist.site?.name ?? "No Site Selected")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        // FIXED: Added the observation count badge
                                        Text("\(checklist.observations.count)")
                                            .font(.subheadline)
                                            .padding(8)
                                            .background(Color.gray.opacity(0.2))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            .onDelete(perform: deleteChecklists)
                        }
                    }
                    .navigationTitle(selectedTab == .sites ? "Sites" : "Checklists")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            EditButton()
                        }

                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: { showingAbout = true }) {
                                Image(systemName: "info.circle")
                            }
                        }
                        
                        ToolbarItemGroup(placement: .bottomBar) {
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
                            
                            Button(action: {
                                if selectedTab == .sites {
                                    showingAddSiteSheet = true
                                } else {
                                    showingAddChecklistSheet = true
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.accentColor)
                            }
                            
                            Menu {
                                Button("Time Created") { sortOption = .byTimeCreated }
                                Button("Alphabetical") { sortOption = .alphabetical }
                            } label: {
                                Image(systemName: "arrow.up.arrow.down")
                            }
                        }
                    }
                    .sheet(isPresented: $showingAbout) {
                        AboutView()
                    }
                    .sheet(isPresented: $showingAddSiteSheet) {
                        SiteCreationView()
                    }
                    .sheet(isPresented: $showingAddChecklistSheet) {
                        ChecklistCreationView()
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
        }
    }

    private func deleteSites(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let siteToDelete = sortedSites[index]
                modelContext.delete(siteToDelete)
            }
        }
    }
    
    private func deleteChecklists(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let checklistToDelete = sortedChecklists[index]
                modelContext.delete(checklistToDelete)
            }
        }
    }
    
    private func startExport(includePhotos: Bool) {
        isExporting = true
        
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            exportURL = ExportManager.createExport(from: checklists, includePhotos: includePhotos)
            isExporting = false
            showingShareSheet = true
        }
    }
}

// A bridge to Apple's native share menu for exporting files
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
