//
//  Models.swift
//  Trillium
//
//  Created by Alex Young on 2/24/26.
//

import Foundation
import SwiftData

@Model
final class Site {
    var name: String
    var creationDate: Date
    var latitude: Double?
    var longitude: Double?
    @Attribute(.externalStorage) var thumbnailData: Data?
    
    // 1. A Site owns many Checklists
    @Relationship(deleteRule: .cascade, inverse: \Checklist.site)
    var checklists: [Checklist] = []
    
    init(name: String, creationDate: Date = Date(), latitude: Double? = nil, longitude: Double? = nil, thumbnailData: Data? = nil) {
        self.name = name
        self.creationDate = creationDate
        self.latitude = latitude
        self.longitude = longitude
        self.thumbnailData = thumbnailData
    }
}

@Model
final class Checklist {
    var name: String
    var creationDate: Date
    var latitude: Double?
    var longitude: Double?
    @Attribute(.externalStorage) var thumbnailData: Data?
    
    // 2. A Checklist belongs to ONE Site
    var site: Site?
    
    // 3. A Checklist owns many Observations
    @Relationship(deleteRule: .cascade, inverse: \PlantObservation.checklist)
    var observations: [PlantObservation] = []
    
    // FIXED: Removed the redundant siteName string parameter
    init(name: String = "", creationDate: Date = Date(), latitude: Double? = nil, longitude: Double? = nil, thumbnailData: Data? = nil) {
        self.name = name
        self.creationDate = creationDate
        self.latitude = latitude
        self.longitude = longitude
        self.thumbnailData = thumbnailData
    }
}

@Model
final class PlantObservation {
    var genus: String
    var species: String
    var infraspecificName: String?
    var isVariety: Bool
    var timestamp: Date
    var latitude: Double?
    var longitude: Double?
    var notes: String
    
    @Attribute(.externalStorage) var photoData: [Data] = []
    
    // 4. An Observation belongs to ONE Checklist
    // FIXED: Removed the direct Site relationship to enforce strict hierarchy
    var checklist: Checklist?
    
    init(genus: String, species: String, infraspecificName: String? = nil, isVariety: Bool = true, timestamp: Date = Date(), latitude: Double? = nil, longitude: Double? = nil, notes: String = "", photoData: [Data] = []) {
        self.genus = genus
        self.species = species
        self.infraspecificName = infraspecificName
        self.isVariety = isVariety
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.notes = notes
        self.photoData = photoData
    }
}
