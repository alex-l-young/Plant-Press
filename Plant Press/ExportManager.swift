import SwiftUI
import SwiftData

struct ExportManager {
    // FIXED: Now accepts Checklists instead of Sites
    static func createExport(from checklists: [Checklist], includePhotos: Bool) -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
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
        
        // NEW: Added Checklist Date to the CSV
        var csvString = "Site Name,Checklist Date,Genus,Species,Type,Infraspecific Name,Latitude,Longitude,Date,Notes,Photos\n"
        
        for checklist in checklists {
            // Safely grab the site name from the checklist
            let siteName = checklist.site?.name ?? "Unknown Site"
            let sName = siteName.replacingOccurrences(of: ",", with: " ")
            let cleanSiteName = sName.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "/", with: "-")
            
            // Format the checklist date for the CSV
            let cDateCSV = checklist.creationDate.formatted(date: .numeric, time: .shortened).replacingOccurrences(of: ",", with: "")
            
            let sitePhotosDir = exportURL
                .appendingPathComponent("Photos", isDirectory: true)
                .appendingPathComponent(cleanSiteName, isDirectory: true)
            
            // Export the Site Thumbnail
            if includePhotos, let siteData = checklist.site?.thumbnailData {
                try? FileManager.default.createDirectory(at: sitePhotosDir, withIntermediateDirectories: true)
                let siteThumbURL = sitePhotosDir.appendingPathComponent("\(cleanSiteName)_Thumbnail.jpg")
                
                // Only write if it doesn't already exist (prevents overwriting the exact same file 10 times if exporting multiple checklists for one site)
                if !FileManager.default.fileExists(atPath: siteThumbURL.path) {
                    try? siteData.write(to: siteThumbURL)
                }
            }
            
            // Export the Checklist Thumbnail
            if includePhotos, let checklistData = checklist.thumbnailData {
                try? FileManager.default.createDirectory(at: sitePhotosDir, withIntermediateDirectories: true)
                let checklistDateStr = formatter.string(from: checklist.creationDate)
                let checklistThumbURL = sitePhotosDir.appendingPathComponent("\(cleanSiteName)_Checklist_\(checklistDateStr).jpg")
                try? checklistData.write(to: checklistThumbURL)
            }
            
            // Loop through observations
            for obs in checklist.observations {
                let genus = obs.genus.replacingOccurrences(of: ",", with: " ")
                let species = obs.species.replacingOccurrences(of: ",", with: " ")
                let infraType = obs.infraspecificName != nil ? (obs.isVariety ? "var." : "ssp.") : ""
                let infraName = obs.infraspecificName?.replacingOccurrences(of: ",", with: " ") ?? ""
                let lat = obs.latitude?.description ?? ""
                let lon = obs.longitude?.description ?? ""
                let date = obs.timestamp.formatted(date: .numeric, time: .shortened).replacingOccurrences(of: ",", with: "")
                let notes = obs.notes.replacingOccurrences(of: ",", with: " ").replacingOccurrences(of: "\n", with: " ")
                
                let genusSpeciesBase = "\(genus)_\(species)"
                    .replacingOccurrences(of: "?", with: "unknown")
                    .replacingOccurrences(of: " ", with: "_")
                    .replacingOccurrences(of: "/", with: "-")
                
                var observationBaseName = genusSpeciesBase
                if !infraName.isEmpty {
                    let typeStr = obs.isVariety ? "var" : "ssp"
                    observationBaseName += "_\(typeStr)_\(infraName)"
                }
                
                let obsTimeStr = formatter.string(from: obs.timestamp)
                observationBaseName += "_\(obsTimeStr)"
                let safeObservationName = observationBaseName.replacingOccurrences(of: " ", with: "_")
                var photosColumn = ""
                
                if includePhotos && !obs.photoData.isEmpty {
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
                        
                        photosColumn = "Photos/\(cleanSiteName)/\(genusSpeciesBase)/\(safeObservationName)"
                        
                    } catch {
                        print("Failed to write photos for \(safeObservationName): \(error)")
                    }
                }
                
                // Add to CSV
                csvString.append("\(sName),\(cDateCSV),\(genus),\(species),\(infraType),\(infraName),\(lat),\(lon),\(date),\(notes),\(photosColumn)\n")
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
