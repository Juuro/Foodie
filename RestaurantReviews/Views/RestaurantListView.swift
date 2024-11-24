import SwiftUI
import SwiftData

struct RestaurantListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var restaurants: [Restaurant]
    @State private var searchText = ""
    @State private var showingAddRestaurant = false
    
    var filteredRestaurants: [Restaurant] {
        if searchText.isEmpty {
            return restaurants
        }
        return restaurants.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredRestaurants) { restaurant in
                    NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                        RestaurantRowView(restaurant: restaurant)
                    }
                }
                .onDelete(perform: deleteRestaurants)
            }
            .navigationTitle("Restaurants")
            .searchable(text: $searchText, prompt: "Search restaurants")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddRestaurant = true }) {
                        Label("Add Restaurant", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddRestaurant) {
                AddRestaurantView()
            }
        }
    }
    
    private func deleteRestaurants(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredRestaurants[index])
        }
    }
} 