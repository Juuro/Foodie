import SwiftUI
import SwiftData
import MapKit
import CoreLocation

// Replace the actor with a class
@MainActor
private class SearchDebouncer: ObservableObject {
    private var task: Task<Void, Never>?
    
    func debounce(delay: TimeInterval, action: @escaping () async -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(for: .milliseconds(Int(delay * 1000)))
            if !Task.isCancelled {
                await action()
            }
        }
    }
}

struct AddRestaurantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingRestaurants: [Restaurant]
    
    private let restaurantService = RestaurantService()
    @StateObject private var locationManager = LocationManagerDelegate()
    
    @State private var searchText = ""
    @State private var searchResults: [RestaurantSearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var locationError: String?
    @FocusState private var isSearchFieldFocused: Bool
    
    @StateObject private var searchDebouncer = SearchDebouncer()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                    .padding(.vertical)
                
                ScrollView {
                    if isSearching {
                        ProgressView()
                            .padding()
                    } else if !searchText.isEmpty {
                        if searchResults.isEmpty {
                            ContentUnavailableView {
                                Label("No Results", systemImage: "magnifyingglass")
                            } description: {
                                Text("Try a different search term")
                            }
                        } else {
                            ForEach(searchResults) { result in
                                restaurantRow(for: result)
                            }
                        }
                    }
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
            .onAppear {
                locationManager.requestLocationPermission()
            }
            .onChange(of: locationManager.authorizationStatus) { oldValue, newValue in
                if newValue == .authorizedWhenInUse || newValue == .authorizedAlways {
                    // If user has entered search text, refresh results with location
                    if !searchText.isEmpty {
                        Task {
                            await searchRestaurants()
                        }
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
                .focused($isSearchFieldFocused)
                .onChange(of: searchText) { oldValue, newValue in
                    // Don't search if text is empty
                    guard !newValue.isEmpty else {
                        searchResults = []
                        return
                    }
                    
                    // Debounce search to avoid too many API calls
                    Task {
                        searchDebouncer.debounce(delay: 0.5) {
                            await searchRestaurants()
                        }
                    }
                }
            
            if !searchText.isEmpty {
                Button(action: { 
                    searchText = ""
                    searchResults = []
                }) {
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
            // Use current location if available
            let location = locationManager.location
            searchResults = try await restaurantService.searchRestaurants(
                query: searchText,
                location: location // Pass the location to get nearby results
            )
            
            // Sort results by distance if we have a location
            if let userLocation = location {
                searchResults.sort { first, second in
                    let firstLocation = CLLocation(latitude: first.latitude, longitude: first.longitude)
                    let secondLocation = CLLocation(latitude: second.latitude, longitude: second.longitude)
                    return firstLocation.distance(from: userLocation) < secondLocation.distance(from: userLocation)
                }
            }
        } catch let error as RestaurantService.ServiceError {
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
            longitude: result.longitude,
            website: result.website
        )
        
        modelContext.insert(restaurant)
        dismiss()
    }
    
    private func restaurantRow(for result: RestaurantSearchResult) -> some View {
        Group {
            if let existingRestaurant = findExistingRestaurant(for: result) {
                NavigationLink(destination: RestaurantDetailView(restaurant: existingRestaurant)) {
                    ExistingRestaurantRow(result: result)
                }
            } else {
                Button(action: { addRestaurant(result) }) {
                    NewRestaurantRow(result: result)
                }
            }
        }
    }
}

// Separate class for location manager delegate
class LocationManagerDelegate: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager: CLLocationManager
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    
    override init() {
        manager = CLLocationManager()
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func requestLocationPermission() {
        // Only request if not determined
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        // Only update location if it's recent and accurate enough
        let howRecent = newLocation.timestamp.timeIntervalSinceNow
        guard abs(howRecent) < 15.0,
              newLocation.horizontalAccuracy < 100 else { return }
        
        DispatchQueue.main.async {
            self.location = newLocation
            
            // Only stop updates if we have a good location
            if newLocation.horizontalAccuracy <= self.manager.desiredAccuracy {
                self.manager.stopUpdatingLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

// Add these structs before the #Preview
private struct ExistingRestaurantRow: View {
    let result: RestaurantSearchResult
    
    var body: some View {
        HStack(spacing: 16) {
            // Restaurant icon with category-specific symbol
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(.systemGray6))
                    .frame(width: 44, height: 44)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 18))
                    .foregroundColor(.accentColor)
            }
            
            // Restaurant info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(result.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                
                Text(result.address)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text("Already in your list")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Navigation indicator
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundColor(Color(.systemGray3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
    }
    
    private var categoryIcon: String {
        if let category = result.mapItem?.pointOfInterestCategory {
            switch category {
            case .restaurant: return "fork.knife"
            case .cafe: return "cup.and.saucer.fill"
            case .bakery: return "birthday.cake.fill"
            case .brewery: return "mug.fill"
            case .winery: return "wineglass.fill"
            case .foodMarket: return "basket.fill"
            default: return "fork.knife"
            }
        }
        return "figure.and.child.holdinghands"
    }
}

private struct NewRestaurantRow: View {
    let result: RestaurantSearchResult
    
    var body: some View {
        HStack(spacing: 16) {
            // Restaurant icon with category-specific symbol
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(.systemGray6))
                    .frame(width: 44, height: 44)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 18))
                    .foregroundColor(.accentColor)
            }
            
            // Restaurant info
            VStack(alignment: .leading, spacing: 4) {
                Text(result.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(result.address)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Add button
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 22))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(.accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
    }
    
    private var categoryIcon: String {
        if let category = result.mapItem?.pointOfInterestCategory {
            switch category {
            case .restaurant: return "fork.knife"
            case .cafe: return "cup.and.saucer.fill"
            case .bakery: return "birthday.cake.fill"
            case .brewery: return "mug.fill"
            case .winery: return "wineglass.fill"
            case .foodMarket: return "basket.fill"
            default: return "fork.knife"
            }
        }
        return "figure.and.child.holdinghands"
    }
}

#Preview {
    AddRestaurantView()
        .modelContainer(for: Restaurant.self)
} 
