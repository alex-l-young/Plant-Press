import SwiftUI
import SwiftData

struct ExportManager {
    static func createExport(from sites: [Site], includePhotos: Bool) -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss" // Enforces the exact timestamp format you requested
        let timestamp = formatter.string(from: Date())
        let baseName = "FloraExport_\(timestamp)"
        
        let tempDir = FileManager.default.temporaryDirectory
        let exportURL: URL
        
        if includePhotos {
            exportURL = tempDir.appendingPathComponent(baseName, isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: exportURL, withIntermediateDirectories: true)
            } catch {
                print("Failed to create export directory: \(error)")
                return nil
            }
        } else {
            exportURL = tempDir.appendingPathComponent("\(baseName).csv")
        }
        
        var csvString = "Site Name,Genus,Species,Type,Infraspecific Name,Latitude,Longitude,Date,Notes,Photos\n"
        
        for site in sites {
            // Sanitize the site name for folder creation
            let sName = site.name.replacingOccurrences(of: ",", with: " ")
            let cleanSiteName = sName.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "/", with: "-")
            
            let sitePhotosDir = exportURL
                .appendingPathComponent("Photos", isDirectory: true)
                .appendingPathComponent(cleanSiteName, isDirectory: true)
            
            // NEW: Export the Site Thumbnail
            if includePhotos, let siteData = site.thumbnailData {
                try? FileManager.default.createDirectory(at: sitePhotosDir, withIntermediateDirectories: true)
                let siteThumbURL = sitePhotosDir.appendingPathComponent("\(cleanSiteName)_Thumbnail.jpg")
                try? siteData.write(to: siteThumbURL)
            }
            
            for obs in site.observations {
                let genus = obs.genus.replacingOccurrences(of: ",", with: " ")
                let species = obs.species.replacingOccurrences(of: ",", with: " ")
                let infraType = obs.infraspecificName != nil ? (obs.isVariety ? "var." : "ssp.") : ""
                let infraName = obs.infraspecificName?.replacingOccurrences(of: ",", with: " ") ?? ""
                let lat = obs.latitude?.description ?? ""
                let lon = obs.longitude?.description ?? ""
                let date = obs.timestamp.formatted(date: .numeric, time: .shortened).replacingOccurrences(of: ",", with: "")
                let notes = obs.notes.replacingOccurrences(of: ",", with: " ").replacingOccurrences(of: "\n", with: " ")
                
                // Construct the Genus_species folder level
                let genusSpeciesBase = "\(genus)_\(species)"
                    .replacingOccurrences(of: "?", with: "unknown")
                    .replacingOccurrences(of: " ", with: "_")
                    .replacingOccurrences(of: "/", with: "-")
                
                // Construct the highly specific Observation folder level
                var observationBaseName = genusSpeciesBase
                if !infraName.isEmpty {
                    let typeStr = obs.isVariety ? "var" : "ssp"
                    observationBaseName += "_\(typeStr)_\(infraName)"
                }
                
                // Append the exact seconds timestamp to the observation string
                let obsTimeStr = formatter.string(from: obs.timestamp)
                observationBaseName += "_\(obsTimeStr)"
                
                // Final sanitization
                let safeObservationName = observationBaseName.replacingOccurrences(of: " ", with: "_")
                
                var photosColumn = ""
                
                if includePhotos && !obs.photoData.isEmpty {
                    // Build the full path: Photos / SiteName / Genus_species / Genus_species_var_Timestamp
                    let specificObsDir = sitePhotosDir
                        .appendingPathComponent(genusSpeciesBase, isDirectory: true)
                        .appendingPathComponent(safeObservationName, isDirectory: true)
                    
                    do {
                        try FileManager.default.createDirectory(at: specificObsDir, withIntermediateDirectories: true)
                        
                        for (index, data) in obs.photoData.enumerated() {
                            let photoName = "\(safeObservationName)_\(index + 1).jpg"
                            let photoURL = specificObsDir.appendingPathComponent(photoName)
                            try data.write(to: photoURL)
                        }
                        
                        // Set the CSV column to match this deeply nested relative path
                        photosColumn = "Photos/\(cleanSiteName)/\(genusSpeciesBase)/\(safeObservationName)"
                        
                    } catch {
                        print("Failed to write photos for \(safeObservationName): \(error)")
                    }
                }
                
                csvString.append("\(sName),\(genus),\(species),\(infraType),\(infraName),\(lat),\(lon),\(date),\(notes),\(photosColumn)\n")
            }
        }
        
        do {
            if includePhotos {
                let csvURL = exportURL.appendingPathComponent("\(baseName).csv")
                try csvString.write(to: csvURL, atomically: true, encoding: .utf8)
                return exportURL
            } else {
                try csvString.write(to: exportURL, atomically: true, encoding: .utf8)
                return exportURL
            }
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }
}
