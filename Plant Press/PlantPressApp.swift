//
//  PlantPressApp.swift
//  Plant Press
//
//  Created by Alex Young on 2/25/26.
//

import SwiftUI
import SwiftData

@main
struct TrilliumApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Updated to PlantObservation.self
        .modelContainer(for: [Site.self, PlantObservation.self])
    }
}
