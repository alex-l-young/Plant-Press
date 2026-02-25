//
//  PlantDataManager.swift
//  Trillium
//
//  Created by Alex Young on 2/24/26.
//
import Foundation
internal import Combine // This satisfies Swift 6 strict access levels!

class PlantDataManager: ObservableObject {
    // Singleton instance so we only load the CSV once
    static let shared = PlantDataManager()
    
    @Published var allGenera: [String] = []
    @Published var speciesByGenus: [String: [String]] = [:]
    
    init() {
        loadData()
    }
    
    func loadData() {
        // Look for the file in the app bundle
        guard let url = Bundle.main.url(forResource: "NY All Plant Names", withExtension: "csv") else {
            print("CSV file not found.")
            return
        }
        
        do {
            // Explicitly stating .utf8 encoding to satisfy iOS 18 requirements
            let data = try String(contentsOf: url, encoding: .utf8)
            
            // Handle universal line endings
            var rows = data.components(separatedBy: .newlines)
            
            // Remove the header row if it exists
            if let first = rows.first, first.contains("Scientific_Name") {
                rows.removeFirst()
            }
            
            var tempSpeciesByGenus: [String: Set<String>] = [:]
            
            for row in rows {
                let columns = row.components(separatedBy: ",")
                // We need at least Genus (col 1) and Species (col 2)
                if columns.count >= 3 {
                    let genus = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let species = columns[2].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if !genus.isEmpty && !species.isEmpty {
                        // Initialize the set if it doesn't exist
                        if tempSpeciesByGenus[genus] == nil {
                            tempSpeciesByGenus[genus] = []
                        }
                        // Insert the species (Set handles duplicates automatically)
                        tempSpeciesByGenus[genus]?.insert(species)
                    }
                }
            }
            
            // Convert to sorted arrays for the UI
            DispatchQueue.main.async {
                self.allGenera = tempSpeciesByGenus.keys.sorted()
                self.speciesByGenus = tempSpeciesByGenus.mapValues { $0.sorted() }
            }
            
        } catch {
            print("Error parsing CSV: \(error)")
        }
    }
}
