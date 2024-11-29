//
//  FoodieFootprintsApp.swift
//  FoodieFootprints
//
//  Created by Sebastian Engel on 24.11.24.
//

import SwiftUI
import SwiftData

@main
struct FoodieFootprintsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Restaurant.self,
            Visit.self,
            Visit.Photo.self
        ])
        
        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
