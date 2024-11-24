import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct AddRestaurantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var locationManager = LocationManager()
    private let yelpService = YelpService()
    
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
    
    private func searchRestaurants() async {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        do {
            searchResults = try await yelpService.searchRestaurants(
                query: searchText,
                location: locationManager.location
            )
        } catch YelpService.YelpError.invalidResponse {
            errorMessage = "Unable to connect to restaurant service. Please try again."
        } catch YelpService.YelpError.decodingError {
            errorMessage = "There was a problem processing the restaurant data."
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
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

// This would typically come from your API response
struct RestaurantSearchResult: Identifiable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}

#Preview {
    AddRestaurantView()
        .modelContainer(for: Restaurant.self)
} 