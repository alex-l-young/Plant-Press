//
//  PlantDataManager.swift
//  Trillium
//
//  Created by Alex Young on 2/24/26.
//
import Foundation
internal import Combine

class PlantDataManager: ObservableObject {
    static let shared = PlantDataManager()
    
    @Published var allGenera: [String] = []
    @Published var speciesByGenus: [String: [String]] = [:]
    
    // NEW: Dictionary to hold infraspecific options based on "Genus Species" key
    @Published var infraspecificBySpecies: [String: [String]] = [:]
    
    init() {
        loadData()
    }
    
    func loadData() {
        guard let url = Bundle.main.url(forResource: "NY All Plant Names Infra", withExtension: "csv") else {
            print("CSV file not found.")
            return
        }
        
        do {
            let data = try String(contentsOf: url, encoding: .utf8)
            var rows = data.components(separatedBy: .newlines)
            
            if let first = rows.first, first.contains("Scientific_Name") {
                rows.removeFirst()
            }
            
            var tempSpeciesByGenus: [String: Set<String>] = [:]
            var tempInfraBySpecies: [String: Set<String>] = [:] // NEW: Temporary set for infraspecific names
            
            for row in rows {
                let columns = row.components(separatedBy: ",")
                
                if columns.count >= 3 {
                    let genus = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let species = columns[2].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // NEW: Safely extract the 4th column if it exists
                    var infra = ""
                    if columns.count >= 4 {
                        infra = columns[3].trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    
                    if !genus.isEmpty && !species.isEmpty {
                        if tempSpeciesByGenus[genus] == nil {
                            tempSpeciesByGenus[genus] = []
                        }
                        tempSpeciesByGenus[genus]?.insert(species)
                        
                        // NEW: Map the infraspecific name to the "Genus Species" key
                        if !infra.isEmpty {
                            let key = "\(genus) \(species)"
                            if tempInfraBySpecies[key] == nil {
                                tempInfraBySpecies[key] = []
                            }
                            tempInfraBySpecies[key]?.insert(infra)
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.allGenera = tempSpeciesByGenus.keys.sorted()
                self.speciesByGenus = tempSpeciesByGenus.mapValues { $0.sorted() }
                self.infraspecificBySpecies = tempInfraBySpecies.mapValues { $0.sorted() }
            }
            
        } catch {
            print("Error parsing CSV: \(error)")
        }
    }
}
