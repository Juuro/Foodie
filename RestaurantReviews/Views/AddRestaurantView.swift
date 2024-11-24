import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct AddRestaurantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingRestaurants: [Restaurant]
    
    @StateObject private var locationManager = LocationManager()
    private let mapKitService = MapKitService()
    
    @State private var searchText = ""
    @State private var searchResults: [RestaurantSearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack {
                searchField
                
                if isSearching {
                    ProgressView()
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .padding()
                } else {
                    resultsList
                }
            }
            .navigationTitle("Add Restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search for a restaurant", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .onSubmit {
                    Task {
                        await searchRestaurants()
                    }
                }
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.gray.opacity(0.1))
        }
        .padding()
    }
    
    private var resultsList: some View {
        List(searchResults) { result in
            if let existingRestaurant = findExistingRestaurant(for: result) {
                NavigationLink(destination: RestaurantDetailView(restaurant: existingRestaurant)) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(result.name)
                                .font(.headline)
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        
                        Text(result.address)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("Already in your list")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                }
            } else {
                Button(action: { addRestaurant(result) }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(result.name)
                            .font(.headline)
                        
                        Text(result.address)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
            }
        }
    }
    
    private func findExistingRestaurant(for result: RestaurantSearchResult) -> Restaurant? {
        // First try to find by ID
        if let restaurant = existingRestaurants.first(where: { $0.id == result.id }) {
            return restaurant
        }
        
        // Then try to find by matching name and coordinates (within a small radius)
        return existingRestaurants.first { restaurant in
            let nameMatches = restaurant.name.lowercased() == result.name.lowercased()
            let coordinateMatches = abs(restaurant.latitude - result.latitude) < 0.0001 &&
                                  abs(restaurant.longitude - result.longitude) < 0.0001
            return nameMatches && coordinateMatches
        }
    }
    
    private func searchRestaurants() async {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        do {
            searchResults = try await mapKitService.searchRestaurants(
                query: searchText,
                location: locationManager.location
            )
        } catch let error as MapKitService.MapKitError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        
        isSearching = false
    }
    
    private func addRestaurant(_ result: RestaurantSearchResult) {
        let restaurant = Restaurant(
            id: result.id,
            name: result.name,
            address: result.address,
            latitude: result.latitude,
            longitude: result.longitude
        )
        
        modelContext.insert(restaurant)
        dismiss()
    }
}

#Preview {
    AddRestaurantView()
        .modelContainer(for: Restaurant.self)
} 