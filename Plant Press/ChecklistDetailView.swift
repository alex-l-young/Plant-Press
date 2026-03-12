//
//  ChecklistDetailView.swift
//  Plant Press
//
//  Created by Alex Young on 2/28/26.
//

import SwiftUI
import SwiftData

struct ChecklistDetailView: View {
    @Environment(\.editMode) private var editMode
    @Bindable var checklist: Checklist
    
    @State private var sortOption: SortOption = .alphabetical
    enum SortOption { case alphabetical, byTime }
    
    @State private var showingEditChecklistSheet = false
    @State private var showingAddObservationSheet = false
    
    // Export & Sort States
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    @State private var isExporting = false
    @State private var showingExportOptions = false
    @State private var showingSortOptions = false // NEW
    
    @State private var selectedGroups = Set<String>()
    
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
            List(selection: $selectedGroups) {
                if groupedObservations.isEmpty {
                    ContentUnavailableView(
                        "No Plants Yet",
                        systemImage: "leaf",
                        description: Text("Tap the + button to add your first observation.")
                    )
                } else {
                    ForEach(groupedObservations) { group in
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
            .navigationTitle(checklist.creationDate.formatted(date: .abbreviated, time: .shortened))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(checklist.creationDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.headline)
                        
                        if let siteName = checklist.site?.name {
                            Text(siteName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack {
                        if editMode?.wrappedValue.isEditing == true {
                            Spacer()
                            Text("\(selectedGroups.count) Selected")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            
                            Button(action: deleteSelectedGroups) {
                                ToolbarIconView(icon: "trash", text: "Delete")
                                    .foregroundColor(selectedGroups.isEmpty ? .gray : .red)
                            }
                            .disabled(selectedGroups.isEmpty)
                            
                        } else {
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
                            
                            // 3. Add Obs Button
                            Button(action: { showingAddObservationSheet = true }) {
                                ToolbarIconView(icon: "plus.circle.fill", text: "Add Obs", isProminent: true)
                            }
                            .offset(y: -4)
                            
                            Spacer()
                            
                            // 4. Map Button
                            if let site = checklist.site {
                                NavigationLink(destination: SiteMapView(site: site)) {
                                    ToolbarIconView(icon: "map", text: "Map")
                                }
                            } else {
                                Color.clear.frame(width: 50, height: 50)
                            }
                            
                            Spacer()
                            
                            // 5. Sort Button
                            Button(action: { showingSortOptions = true }) {
                                ToolbarIconView(icon: "arrow.up.arrow.down", text: "Sort")
                            }
                            .confirmationDialog("Sort By", isPresented: $showingSortOptions, titleVisibility: .visible) {
                                Button("Time Created") { sortOption = .byTime }
                                Button("Alphabetical") { sortOption = .alphabetical }
                                Button("Cancel", role: .cancel) {}
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                }
                .background(.regularMaterial)
            }
            .sheet(isPresented: $showingEditChecklistSheet) {
                ChecklistCreationView(checklistToEdit: checklist)
            }
            .sheet(isPresented: $showingAddObservationSheet) {
                ObservationCreationView(checklist: checklist)
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
    
    private func deleteSpeciesGroup(at offsets: IndexSet) {
        for index in offsets {
            let group = groupedObservations[index]
            for observation in group.observations {
                checklist.modelContext?.delete(observation)
            }
        }
    }
    
    private func deleteSelectedGroups() {
        for groupId in selectedGroups {
            if let group = groupedObservations.first(where: { $0.id == groupId }) {
                for observation in group.observations {
                    checklist.modelContext?.delete(observation)
                }
            }
        }
        selectedGroups.removeAll()
        editMode?.wrappedValue = .inactive
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

struct SpeciesGroup: Identifiable {
    let id: String
    let genus: String
    let species: String
    let count: Int
    let observations: [PlantObservation]
    let latestDate: Date
}
