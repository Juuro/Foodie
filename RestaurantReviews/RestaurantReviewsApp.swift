//
//  RestaurantReviewsApp.swift
//  RestaurantReviews
//
//  Created by Sebastian Engel on 24.11.24.
//

import SwiftUI
import SwiftData

@main
struct RestaurantReviewsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Restaurant.self,
            Visit.self,
            Visit.Photo.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
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
