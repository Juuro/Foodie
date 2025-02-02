import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query private var restaurants: [Restaurant]
    @State private var timeRange: TimeRange = .allTime
    
    enum TimeRange {
        case last30Days
        case last90Days
        case last12Months
        case allTime
        
        var label: String {
            switch self {
            case .last30Days: "Last 30 Days"
            case .last90Days: "Last 90 Days"
            case .last12Months: "Last 12 Months"
            case .allTime: "All Time"
            }
        }
    }
    
    var filteredVisits: [Visit] {
        let allVisits = restaurants.flatMap { $0.visits }
        let cutoffDate: Date
        
        switch timeRange {
        case .last30Days:
            cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        case .last90Days:
            cutoffDate = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        case .last12Months:
            cutoffDate = Calendar.current.date(byAdding: .month, value: -12, to: Date()) ?? Date()
        case .allTime:
            return allVisits
        }
        
        return allVisits.filter { $0.date >= cutoffDate }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Time Range Picker - Always visible
                Picker("Time Range", selection: $timeRange) {
                    Text("Last 30 Days").tag(TimeRange.last30Days)
                    Text("Last 90 Days").tag(TimeRange.last90Days)
                    Text("Last 12 Months").tag(TimeRange.last12Months)
                    Text("All Time").tag(TimeRange.allTime)
                }
                .pickerStyle(.segmented)
                .padding()
                .background(.background)
                
                // Scrollable content
                List {
                    // General Statistics
                    Section("Overview") {
                        StatCard(title: String(localized: "Total Restaurants"), value: "\(restaurants.count)")
                        StatCard(title: String(localized: "Total Visits"), value: "\(filteredVisits.count)")
                        if let averageRating = calculateAverageRating() {
                            StatCard(title: String(localized: "Average Rating"), value: String(format: "%.1f", averageRating))
                        }
                        if let mostVisited = mostVisitedRestaurant {
                            NavigationLink {
                                RestaurantDetailView(restaurant: mostVisited.restaurant)
                            } label: {
                                StatCard(
                                    title: String(localized: "Most Visited"),
                                    value: mostVisited.restaurant.name,
                                    detail: "\(mostVisited.count) \(String(localized: "visits"))"
                                )
                            }
                        }
                    }
                    
                    // Most Visited Restaurants
                    Section("Most Visited Restaurants") {
                        ForEach(topVisitedRestaurants.prefix(5), id: \.restaurant.id) { item in
                            NavigationLink {
                                RestaurantDetailView(restaurant: item.restaurant)
                            } label: {
                                HStack {
                                    Text(item.restaurant.name)
                                    Spacer()
                                    Text("\(item.count) \(String(localized: "visits"))")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Highest Rated Restaurants
                    Section("Highest Rated Restaurants") {
                        ForEach(topRatedRestaurants.prefix(5), id: \.restaurant.id) { item in
                            NavigationLink {
                                RestaurantDetailView(restaurant: item.restaurant)
                            } label: {
                                HStack {
                                    Text(item.restaurant.name)
                                    Spacer()
                                    Text(String(format: "%.1f ★", item.rating))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Most Visited Cities
                    Section("Most Visited Cities") {
                        ForEach(topVisitedCities.prefix(5), id: \.city) { item in
                            HStack {
                                Text(item.city)
                                Spacer()
                                Text("\(item.count) \(String(localized: "visits"))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Ratings Distribution
                    Section("Ratings Distribution") {
                        VStack(spacing: 12) {
                            ForEach(ratingDistribution.reversed(), id: \.rating) { item in
                                HStack(alignment: .center, spacing: 12) {
                                    Text("\(item.rating) ★")
                                        .font(.title3)
                                        .frame(width: 40, alignment: .trailing)
                                        .foregroundStyle(.primary)
                                    
                                    GeometryReader { geometry in
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.yellow.gradient)
                                            .frame(width: geometry.size.width * CGFloat(item.count) / CGFloat(maxCount))
                                    }
                                    .frame(height: 25)
                                    
                                    Text("\(item.count)")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 30, alignment: .trailing)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    // Visits Over Time
                    Section("Visits Over Time") {
                        Chart(visitsOverTime, id: \.date) { item in
                            LineMark(
                                x: .value("Date", item.date),
                                y: .value("Visits", item.count)
                            )
                            .foregroundStyle(.blue)
                        }
                        .frame(height: 200)
                    }
                    
                    // Photos Statistics
                    Section("Photos") {
                        let totalPhotos = filteredVisits.reduce(0) { $0 + $1.photos.count }
                        StatCard(title: String(localized: "Total Photos"), value: "\(totalPhotos)")
                        if let mostPhotographed = mostPhotographedRestaurant {
                            NavigationLink {
                                RestaurantDetailView(restaurant: mostPhotographed.restaurant)
                            } label: {
                                StatCard(
                                    title: String(localized: "Most Photos"),
                                    value: mostPhotographed.restaurant.name,
                                    detail: "\(mostPhotographed.count) \(String(localized: "photos"))"
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "Statistics"))
        }
    }
    
    private func calculateAverageRating() -> Double? {
        let restaurantsWithRatings = restaurants.filter { $0.averageRating > 0 }
        guard !restaurantsWithRatings.isEmpty else { return nil }
        return restaurantsWithRatings.reduce(0.0) { $0 + $1.averageRating } / Double(restaurantsWithRatings.count)
    }
    
    private var topVisitedRestaurants: [(restaurant: Restaurant, count: Int)] {
        let visitCounts = restaurants
            .map { restaurant in
                let count = restaurant.visits.filter { visit in
                    filteredVisits.contains { $0.id == visit.id }
                }.count
                return (restaurant: restaurant, count: count)
            }
            .filter { $0.count > 0 }
            .sorted { $0.count > $1.count }
        
        return visitCounts
    }
    
    private var mostVisitedRestaurant: (restaurant: Restaurant, count: Int)? {
        topVisitedRestaurants.first
    }
    
    private var topRatedRestaurants: [(restaurant: Restaurant, rating: Double)] {
        restaurants
            .filter { !$0.visits.isEmpty }
            .map { restaurant in
                let filteredRestaurantVisits = restaurant.visits.filter { visit in
                    filteredVisits.contains { $0.id == visit.id }
                }
                let rating = filteredRestaurantVisits.isEmpty ? 0 :
                    filteredRestaurantVisits.reduce(0.0) { $0 + $1.rating } / Double(filteredRestaurantVisits.count)
                return (restaurant: restaurant, rating: rating)
            }
            .filter { $0.rating > 0 }
            .sorted { $0.rating > $1.rating }
    }
    
    private var topVisitedCities: [(city: String, count: Int)] {
        var cityCounts: [String: Int] = [:]
        
        for restaurant in restaurants {
            let city = extractCity(from: restaurant.address)
            let visitCount = restaurant.visits.filter { visit in
                filteredVisits.contains { $0.id == visit.id }
            }.count
            if visitCount > 0 {
                cityCounts[city, default: 0] += visitCount
            }
        }
        
        return cityCounts
            .map { (city: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    private func extractCity(from address: String) -> String {
        let components = address.components(separatedBy: "\n")
        // Assuming city is in the second line (after street address)
        if components.count >= 2 {
            let cityLine = components[1]
            // Extract city name (after postal code if present)
            if let cityName = cityLine.split(separator: " ").dropFirst().joined(separator: " ").nilIfEmpty {
                return cityName
            }
        }
        return "Unknown"
    }
    
    private var mostPhotographedRestaurant: (restaurant: Restaurant, count: Int)? {
        let photoCounts = restaurants.map { restaurant in
            let count = restaurant.visits
                .filter { visit in filteredVisits.contains { $0.id == visit.id } }
                .reduce(0) { $0 + $1.photos.count }
            return (restaurant: restaurant, count: count)
        }
        return photoCounts.max(by: { $0.count < $1.count })
    }
    
    private var ratingDistribution: [(rating: Int, count: Int)] {
        var distribution = [Int: Int]()
        for visit in filteredVisits {
            let rating = Int(visit.rating)
            distribution[rating, default: 0] += 1
        }
        return (1...5).map { rating in
            (rating: rating, count: distribution[rating] ?? 0)
        }
    }
    
    private var visitsOverTime: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let visits = filteredVisits.sorted { $0.date < $1.date }
        
        // Get start date based on time range
        let startDate: Date
        switch timeRange {
        case .last30Days:
            startDate = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        case .last90Days:
            startDate = calendar.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        case .last12Months:
            startDate = calendar.date(byAdding: .month, value: -12, to: Date()) ?? Date()
        case .allTime:
            startDate = visits.first?.date ?? Date()
        }
        
        let endDate = Date()
        var currentDate = startDate
        var result: [(date: Date, count: Int)] = []
        
        // Determine interval based on time range
        let interval: Calendar.Component
        switch timeRange {
        case .last30Days:
            interval = .day
        case .last90Days:
            interval = .weekOfYear
        case .last12Months:
            interval = .month
        case .allTime:
            interval = .month
        }
        
        // Create data points for each interval
        while currentDate <= endDate {
            let nextDate = calendar.date(byAdding: interval, value: 1, to: currentDate) ?? currentDate
            let periodVisits = visits.filter { visit in
                visit.date >= currentDate && visit.date < nextDate
            }
            result.append((date: currentDate, count: periodVisits.count))
            currentDate = nextDate
        }
        
        return result
    }
    
    private var maxCount: Int {
        ratingDistribution.map { $0.count }.max() ?? 1
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    var detail: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
            if let detail = detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

extension String {
    var nilIfEmpty: String? {
        self.isEmpty ? nil : self
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: Restaurant.self)
} 
