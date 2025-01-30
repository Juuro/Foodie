import SwiftUI
import SwiftData

struct RestaurantListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var restaurants: [Restaurant]
    @State private var searchText = ""
    @State private var showingAddRestaurant = false
    @State private var sortOption: SortOption = .lastVisit
    
    enum SortOption {
        case name
        case rating
        case lastVisit
        case lastAdded
        
        var label: String {
            switch self {
            case .name: "Name"
            case .rating: "Rating"
            case .lastVisit: "Last Visit"
            case .lastAdded: "Last Added"
            }
        }
    }
    
    var filteredAndSortedRestaurants: [Restaurant] {
        let filtered = searchText.isEmpty ? restaurants : restaurants.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
        
        return filtered.sorted { first, second in
            switch sortOption {
            case .name:
                return first.name.localizedCompare(second.name) == .orderedAscending
            case .rating:
                return first.averageRating > second.averageRating
            case .lastVisit:
                if first.visits.isEmpty && second.visits.isEmpty {
                    return first.createdAt > second.createdAt
                }
                if first.visits.isEmpty {
                    return false
                }
                if second.visits.isEmpty {
                    return true
                }
                let firstDate = first.visits.max(by: { $0.date < $1.date })?.date ?? .distantPast
                let secondDate = second.visits.max(by: { $0.date < $1.date })?.date ?? .distantPast
                return firstDate > secondDate
            case .lastAdded:
                return first.createdAt > second.createdAt
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if restaurants.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray)
                        
                        Text("No Restaurants Yet")
                            .font(.title2)
                            .foregroundStyle(.gray)
                        
                        Button {
                            showingAddRestaurant = true
                        } label: {
                            Label("Add Your First Restaurant", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filteredAndSortedRestaurants) { restaurant in
                            NavigationLink {
                                RestaurantDetailView(restaurant: restaurant)
                            } label: {
                                RestaurantRowView(restaurant: restaurant)
                            }
                        }
                        .onDelete(perform: deleteRestaurants)
                    }
                    .searchable(text: $searchText, prompt: "Search your restaurants")
                }
            }
            .navigationTitle("Restaurants")
            .toolbar {
                if !restaurants.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Menu {
                            Picker("Sort By", selection: $sortOption) {
                                Label("Name", systemImage: "textformat")
                                    .tag(SortOption.name)
                                Label("Rating", systemImage: "star")
                                    .tag(SortOption.rating)
                                Label("Last Visit", systemImage: "clock")
                                    .tag(SortOption.lastVisit)
                                Label("Last Added", systemImage: "calendar")
                                    .tag(SortOption.lastAdded)
                            }
                        } label: {
                            Label("Sort", systemImage: "arrow.up.arrow.down")
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    
                    ToolbarItem {
                        Button(action: { showingAddRestaurant = true }) {
                            Label("Add Restaurant", systemImage: "plus")
                        }
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
            modelContext.delete(filteredAndSortedRestaurants[index])
        }
    }
}

#Preview {
    RestaurantListView()
        .modelContainer(for: Restaurant.self)
} 
