import SwiftUI
import SwiftData

struct ExportManager {
    static func createExport(from sites: [Site], includePhotos: Bool) -> URL? {
        // 1. Format the date for the file/folder name
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let baseName = "FloraExport_\(timestamp)"
        
        let tempDir = FileManager.default.temporaryDirectory
        let exportURL: URL
        
        // 2. Setup the directory or file path
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
        
        // 3. Build the CSV String
        var csvString = "Site Name,Genus,Species,Type,Infraspecific Name,Latitude,Longitude,Date,Notes,Photos\n"
        
        var rowIndex = 1
        
        for site in sites {
            for obs in site.observations {
                let sName = site.name.replacingOccurrences(of: ",", with: " ")
                let genus = obs.genus.replacingOccurrences(of: ",", with: " ")
                let species = obs.species.replacingOccurrences(of: ",", with: " ")
                let infraType = obs.infraspecificName != nil ? (obs.isVariety ? "var." : "ssp.") : ""
                let infraName = obs.infraspecificName?.replacingOccurrences(of: ",", with: " ") ?? ""
                let lat = obs.latitude?.description ?? ""
                let lon = obs.longitude?.description ?? ""
                let date = obs.timestamp.formatted(date: .numeric, time: .shortened).replacingOccurrences(of: ",", with: "")
                let notes = obs.notes.replacingOccurrences(of: ",", with: " ").replacingOccurrences(of: "\n", with: " ")
                
                // NEW: Construct the base file name from the taxonomy
                var taxonomyBase = "\(genus)_\(species)"
                if !infraName.isEmpty {
                    let typeStr = obs.isVariety ? "var" : "ssp"
                    taxonomyBase += "_\(typeStr)_\(infraName)"
                }
                
                // Sanitize the string to prevent file system errors
                // (e.g., swapping the "?" quick-fill for "unknown" and removing spaces)
                let safeTaxonomyBase = taxonomyBase
                    .replacingOccurrences(of: "?", with: "unknown")
                    .replacingOccurrences(of: " ", with: "_")
                    .replacingOccurrences(of: "/", with: "-")
                    .replacingOccurrences(of: "\\", with: "-")
                
                var photosColumn = ""
                
                // 4. Handle Photos if requested
                if includePhotos && !obs.photoData.isEmpty {
                    // NEW: Folder is now named Genus_species_var_row
                    let subfolderName = "\(safeTaxonomyBase)_\(rowIndex)"
                    let rowPhotosDir = exportURL
                        .appendingPathComponent("Photos", isDirectory: true)
                        .appendingPathComponent(subfolderName, isDirectory: true)
                    
                    do {
                        try FileManager.default.createDirectory(at: rowPhotosDir, withIntermediateDirectories: true)
                        
                        for (index, data) in obs.photoData.enumerated() {
                            // NEW: Photos are named Genus_species_var_1.jpg
                            let photoName = "\(safeTaxonomyBase)_\(index + 1).jpg"
                            let photoURL = rowPhotosDir.appendingPathComponent(photoName)
                            try data.write(to: photoURL)
                        }
                        
                        photosColumn = "Photos/\(subfolderName)"
                        
                    } catch {
                        print("Failed to write photos for row \(rowIndex): \(error)")
                    }
                }
                
                csvString.append("\(sName),\(genus),\(species),\(infraType),\(infraName),\(lat),\(lon),\(date),\(notes),\(photosColumn)\n")
                
                rowIndex += 1
            }
        }
        
        // 5. Write the final CSV to the appropriate location
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

// SwiftUI wrapper for the standard iOS Share/Export screen
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
