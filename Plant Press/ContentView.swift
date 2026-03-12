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
                            if sortedSites.isEmpty {
                                ContentUnavailableView(
                                    "No Sites Yet",
                                    systemImage: "map",
                                    description: Text("Tap the + button to add your first site.")
                                )
                            } else {
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
                                                Text("\(site.checklists.count) checklist\(site.checklists.count == 1 ? "" : "s")")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                                .onDelete(perform: deleteSites)
                            }
                            
                        } else {
                            if sortedChecklists.isEmpty {
                                ContentUnavailableView(
                                    "No Checklists Yet",
                                    systemImage: "list.clipboard",
                                    description: Text("Tap the + button to add your first checklist.")
                                )
                            } else {
                                ForEach(sortedChecklists) { checklist in
                                    NavigationLink(destination: ChecklistDetailView(checklist: checklist)) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(checklist.creationDate.formatted(date: .abbreviated, time: .shortened))
                                                    .font(.headline)
                                                
                                                Text(checklist.site?.name ?? "No Site Selected")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
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
                    }
                    .safeAreaInset(edge: .bottom) {
                        VStack(spacing: 0) {
                            Divider()
                            
                            HStack {
                                Spacer()
                                // 1. Export Button
                                Button(action: { showingExportOptions = true }) {
                                    ToolbarIconView(icon: "square.and.arrow.up", text: "Export")
                                }
                                .confirmationDialog("Export Options", isPresented: $showingExportOptions, titleVisibility: .visible) {
                                    Button("Export Data Only (CSV)") { startExport(includePhotos: false) }
                                    Button("Export Data + Photos (Folder)") { startExport(includePhotos: true) }
                                    Button("Cancel", role: .cancel) {}
                                }
                                
                                Spacer()
                                Spacer()
                                
                                // 2. Add Button
                                Button(action: {
                                    if selectedTab == .sites {
                                        showingAddSiteSheet = true
                                    } else {
                                        showingAddChecklistSheet = true
                                    }
                                }) {
                                    ToolbarIconView(icon: "plus.circle.fill", text: selectedTab == .sites ? "New Site" : "New List", isProminent: true)
                                }
                                .offset(y: -4)
                                
                                Spacer()
                                Spacer()
                                
                                // 3. Sort Button
                                Button(action: { showingSortOptions = true }) {
                                    ToolbarIconView(icon: "arrow.up.arrow.down", text: "Sort")
                                }
                                .confirmationDialog("Sort By", isPresented: $showingSortOptions, titleVisibility: .visible) {
                                    Button("Time Created") { sortOption = .byTimeCreated }
                                    Button("Alphabetical") { sortOption = .alphabetical }
                                    Button("Cancel", role: .cancel) {}
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                            .padding(.bottom, 5)
                        }
                        .background(.regularMaterial)
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

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ToolbarIconView: View {
    let icon: String
    let text: String
    var isProminent: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: isProminent ? 34 : 22))
                .foregroundColor(isProminent ? .accentColor : .secondary)
            
            Text(text)
                .font(.caption2)
                .foregroundColor(isProminent ? .accentColor : .secondary)
                .bold(isProminent)
        }
        .frame(minWidth: 50)
    }
}
