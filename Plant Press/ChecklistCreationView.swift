//
//  ChecklistCreationView.swift
//  Plant Press
//
//  Created by Alex Young on 2/28/26.
//

import SwiftUI
import SwiftData

struct ChecklistCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Grab all sites, sorted alphabetically for the list
    @Query(sort: \Site.name) private var allSites: [Site]
    
    @State private var creationDate: Date = Date()
    
    // Site Selection States
    @State private var selectedSite: Site? = nil
    @State private var searchText: String = ""
    @State private var showingSiteCreation = false
    
    // FIXED: Added properties to handle both Pre-selecting and Editing
    var preselectedSite: Site? = nil
    var checklistToEdit: Checklist? = nil
    
    // Dynamically filter sites based on the search text
    var filteredSites: [Site] {
        if searchText.isEmpty {
            return allSites
        } else {
            return allSites.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // Check if the typed text exactly matches an existing site
    var exactMatchExists: Bool {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return allSites.contains { $0.name.caseInsensitiveCompare(normalizedSearch) == .orderedSame }
    }
    
    var isFormValid: Bool {
        return selectedSite != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Checklist Details")) {
                    DatePicker("Date & Time", selection: $creationDate)
                }
                
                Section(header: Text("Associated Site")) {
                    if let site = selectedSite {
                        // STATE 1: A site is selected
                        HStack {
                            Text(site.name)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // Button to clear the selection and pick a different site
                            Button(action: {
                                selectedSite = nil
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        // STATE 2: Searching for a site
                        TextField("Search or enter site name...", text: $searchText)
                            .autocorrectionDisabled()
                        
                        // Show the "Create New" button if typing something new
                        if !searchText.isEmpty && !exactMatchExists {
                            Button(action: {
                                showingSiteCreation = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Create new site '\(searchText)'")
                                }
                                .foregroundColor(.accentColor)
                                .bold()
                            }
                        }
                        
                        // The list of existing sites
                        ForEach(filteredSites) { site in
                            Button(action: {
                                selectedSite = site
                            }) {
                                Text(site.name)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            // FIXED: Dynamically update the title
            .navigationTitle(checklistToEdit == nil ? "New Checklist" : "Edit Checklist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChecklist()
                    }
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showingSiteCreation) {
                // Pop open the existing Site Creation form
                SiteCreationView(initialSiteName: searchText)
            }
            .onChange(of: allSites) { oldSites, newSites in
                // Auto-select a newly created site
                if newSites.count > oldSites.count {
                    let oldSet = Set(oldSites)
                    if let newlyAddedSite = newSites.first(where: { !oldSet.contains($0) }) {
                        selectedSite = newlyAddedSite
                        searchText = ""
                    }
                }
            }
            .onAppear {
                // FIXED: Populate the form if we are editing an existing checklist
                if let checklist = checklistToEdit {
                    creationDate = checklist.creationDate
                    selectedSite = checklist.site
                } else if let site = preselectedSite {
                    selectedSite = site
                }
            }
        }
    }
    
    private func saveChecklist() {
        guard let validSite = selectedSite else { return }
        
        if let checklist = checklistToEdit {
            // FIXED: Update the existing checklist instead of creating a new one
            checklist.creationDate = creationDate
            checklist.site = validSite
        } else {
            // Create a brand new checklist
            let newChecklist = Checklist(
                name: "",
                creationDate: creationDate
            )
            newChecklist.site = validSite
            modelContext.insert(newChecklist)
        }
        
        dismiss()
    }
}
