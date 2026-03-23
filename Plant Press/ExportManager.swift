import SwiftUI
import SwiftData

struct ExportManager {
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
        
        var csvString = "Site Name,Checklist Date,Genus,Species,Type,Infraspecific Name,Latitude,Longitude,Date,Notes,Photos\n"
        
        for checklist in checklists {
            let siteName = checklist.site?.name ?? "Unknown Site"
            let sName = siteName.replacingOccurrences(of: ",", with: " ")
            let cleanSiteName = sName.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "/", with: "-")
            
            // FIXED: Strips out the Narrow No-Break Space (\u{202F}) that causes the ‚ÄØ glitch in Excel
            let cDateCSV = checklist.creationDate.formatted(date: .numeric, time: .shortened)
                .replacingOccurrences(of: ",", with: "")
                .replacingOccurrences(of: "\u{202F}", with: " ")
                .replacingOccurrences(of: "\u{00A0}", with: " ")
                
            let checklistDateStr = formatter.string(from: checklist.creationDate)
            
            let checklistFolderName = "Checklist_\(checklistDateStr)"
            
            let sitePhotosDir = exportURL
                .appendingPathComponent("Photos", isDirectory: true)
                .appendingPathComponent(cleanSiteName, isDirectory: true)
            
            let checklistPhotosDir = sitePhotosDir
                .appendingPathComponent(checklistFolderName, isDirectory: true)
            
            if includePhotos {
                try? FileManager.default.createDirectory(at: checklistPhotosDir, withIntermediateDirectories: true)
                
                if let siteData = checklist.site?.thumbnailData {
                    let siteThumbURL = sitePhotosDir.appendingPathComponent("\(cleanSiteName)_Thumbnail.jpg")
                    if !FileManager.default.fileExists(atPath: siteThumbURL.path) {
                        try? siteData.write(to: siteThumbURL)
                    }
                }
            }
            
            for obs in checklist.observations {
                let genus = obs.genus.replacingOccurrences(of: ",", with: " ")
                let species = obs.species.replacingOccurrences(of: ",", with: " ")
                let infraType = obs.infraspecificName != nil ? (obs.isVariety ? "var." : "ssp.") : ""
                let infraName = obs.infraspecificName?.replacingOccurrences(of: ",", with: " ") ?? ""
                
                let lat = obs.latitude != nil ? String(format: "%.6f", obs.latitude!) : ""
                let lon = obs.longitude != nil ? String(format: "%.6f", obs.longitude!) : ""
                
                // FIXED: Strips out the Narrow No-Break Space for the observation dates as well
                let date = obs.timestamp.formatted(date: .numeric, time: .shortened)
                    .replacingOccurrences(of: ",", with: "")
                    .replacingOccurrences(of: "\u{202F}", with: " ")
                    .replacingOccurrences(of: "\u{00A0}", with: " ")
                    
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
                
                if includePhotos {
                    let specificObsDir = checklistPhotosDir
                        .appendingPathComponent(genusSpeciesBase, isDirectory: true)
                        .appendingPathComponent(safeObservationName, isDirectory: true)
                    
                    do {
                        try FileManager.default.createDirectory(at: specificObsDir, withIntermediateDirectories: true)
                        
                        if !obs.photoData.isEmpty {
                            for (index, data) in obs.photoData.enumerated() {
                                let photoName = "\(safeObservationName)_\(index + 1).jpg"
                                let photoURL = specificObsDir.appendingPathComponent(photoName)
                                try data.write(to: photoURL)
                            }
                        }
                        photosColumn = "Photos/\(cleanSiteName)/\(checklistFolderName)/\(genusSpeciesBase)/\(safeObservationName)"
                        
                    } catch {
                        print("Failed to write photos/folders for \(safeObservationName): \(error)")
                    }
                }
                
                csvString.append("\(sName),\(cDateCSV),\(genus),\(species),\(infraType),\(infraName),\(lat),\(lon),\(date),\(notes),\(photosColumn)\n")
            }
        }
        
        do {
            // FIXED: Add a UTF-8 BOM (Byte Order Mark) so Excel automatically reads all special characters perfectly
            var csvData = Data([0xEF, 0xBB, 0xBF])
            if let stringData = csvString.data(using: .utf8) {
                csvData.append(stringData)
            }
            
            if includePhotos {
                let csvURL = exportURL.appendingPathComponent("\(baseName).csv")
                try csvData.write(to: csvURL, options: .atomic)
                return exportURL
            } else {
                try csvData.write(to: exportURL, options: .atomic)
                return exportURL
            }
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }
}
