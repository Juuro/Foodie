//
//  ContentView.swift
//  FoodieFootprints
//
//  Created by Sebastian Engel on 24.11.24.
//

import SwiftUI
import SwiftData
import MapKit

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview("English") {
    ContentView()
        .modelContainer(for: Restaurant.self)
        .environment(\.locale, Locale(identifier: "en"))
}


#Preview("German") {
    ContentView()
        .modelContainer(for: Restaurant.self)
        .environment(\.locale, Locale(identifier: "de"))
}
