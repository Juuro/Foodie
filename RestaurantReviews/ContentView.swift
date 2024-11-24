//
//  ContentView.swift
//  RestaurantReviews
//
//  Created by Sebastian Engel on 24.11.24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Restaurant.self)
}
