import SwiftUI
import SwiftData

struct RestaurantListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Restaurant.name) private var restaurants: [Restaurant]
    @State private var searchText = ""
    @State private var showingSortOptions = false
    @State private var sortOption: SortOption = .name
    @State private var showingAddRestaurant = false
    
    enum SortOption {
        case name, rating, lastVisit, lastAdded, mostVisited
        
        var title: String {
            switch self {
            case .name: String(localized: "Name")
            case .rating: String(localized: "Rating")
            case .lastVisit: String(localized: "Last Visit")
            case .lastAdded: String(localized: "Last Added")
            case .mostVisited: String(localized: "Most Visited")
            }
        }
    }
    
    private var filteredRestaurants: [Restaurant] {
        if searchText.isEmpty {
            return sortedRestaurants
        }
        return sortedRestaurants.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var sortedRestaurants: [Restaurant] {
        restaurants.sorted { first, second in
            switch sortOption {
            case .name:
                return first.name < second.name
            case .rating:
                return first.averageRating > second.averageRating
            case .lastVisit:
                return (first.visits.max(by: { $0.date < $1.date })?.date ?? .distantPast) >
                       (second.visits.max(by: { $0.date < $1.date })?.date ?? .distantPast)
            case .lastAdded:
                return first.id > second.id
            case .mostVisited:
                return first.visits.count > second.visits.count
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            RestaurantListContent(
                restaurants: filteredRestaurants,
                showingAddRestaurant: $showingAddRestaurant,
                showingSortOptions: $showingSortOptions,
                sortOption: $sortOption,
                onDelete: deleteRestaurant
            )
            .searchable(text: $searchText, prompt: String(localized: "Search your restaurants"))
            .navigationTitle(String(localized: "Restaurants"))
            .sheet(isPresented: $showingAddRestaurant) {
                AddRestaurantView()
            }
        }
    }
    
    private func deleteRestaurant(_ restaurant: Restaurant) {
        modelContext.delete(restaurant)
    }
}

private struct RestaurantListContent: View {
    let restaurants: [Restaurant]
    @Binding var showingAddRestaurant: Bool
    @Binding var showingSortOptions: Bool
    @Binding var sortOption: RestaurantListView.SortOption
    let onDelete: (Restaurant) -> Void
    
    var body: some View {
        Group {
            if restaurants.isEmpty {
                EmptyStateView(showingAddRestaurant: $showingAddRestaurant)
            } else {
                RestaurantList(
                    restaurants: restaurants,
                    showingAddRestaurant: $showingAddRestaurant,
                    showingSortOptions: $showingSortOptions,
                    sortOption: $sortOption,
                    onDelete: onDelete
                )
            }
        }
        .background(Color(white: 0.95)) // Slightly darker off-white background
    }
}

private struct EmptyStateView: View {
    @Binding var showingAddRestaurant: Bool
    
    var body: some View {
        ContentUnavailableView {
            Label(String(localized: "No Restaurants Yet"), systemImage: "fork.knife")
        } description: {
            Text(String(localized: "Add Your First Restaurant"))
        } actions: {
            Button(action: { showingAddRestaurant = true }) {
                Label(String(localized: "Add Restaurant"), systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct RestaurantList: View {
    let restaurants: [Restaurant]
    @Binding var showingAddRestaurant: Bool
    @Binding var showingSortOptions: Bool
    @Binding var sortOption: RestaurantListView.SortOption
    let onDelete: (Restaurant) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(restaurants) { restaurant in
                    NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                        RestaurantPreview(restaurant: restaurant, onDelete: { onDelete(restaurant) })
                        .padding(.horizontal)
                        .padding(.vertical)
                    }
                    
                    if restaurant != restaurants.last {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
            }
            .padding(.horizontal)
        }
        .scrollContentBackground(.hidden)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                SortButton(showingSortOptions: $showingSortOptions, sortOption: $sortOption)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                AddButton(showingAddRestaurant: $showingAddRestaurant)
            }
        }
    }
}

private struct SortButton: View {
    @Binding var showingSortOptions: Bool
    @Binding var sortOption: RestaurantListView.SortOption
    
    var body: some View {
        Menu {
            Picker(String(localized: "Sort By"), selection: $sortOption) {
                Text(RestaurantListView.SortOption.name.title).tag(RestaurantListView.SortOption.name)
                Text(RestaurantListView.SortOption.rating.title).tag(RestaurantListView.SortOption.rating)
                Text(RestaurantListView.SortOption.lastVisit.title).tag(RestaurantListView.SortOption.lastVisit)
                Text(RestaurantListView.SortOption.lastAdded.title).tag(RestaurantListView.SortOption.lastAdded)
                Text(RestaurantListView.SortOption.mostVisited.title).tag(RestaurantListView.SortOption.mostVisited)
            }
        } label: {
            Label(String(localized: "Sort"), systemImage: "arrow.up.arrow.down")
        }
    }
}

private struct AddButton: View {
    @Binding var showingAddRestaurant: Bool
    
    var body: some View {
        Button {
            showingAddRestaurant = true
        } label: {
            Label(String(localized: "Add Restaurant"), systemImage: "plus")
        }
    }
}

#Preview {
    RestaurantListView()
        .modelContainer(for: Restaurant.self)
} 
