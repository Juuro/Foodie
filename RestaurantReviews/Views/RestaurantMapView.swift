import SwiftUI
import MapKit
import SwiftData

struct RestaurantMapView: View {
    @Query private var restaurants: [Restaurant]
    @State private var selectedRestaurant: Restaurant?
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                ForEach(restaurants) { restaurant in
                    Annotation(
                        restaurant.name,
                        coordinate: restaurant.coordinate,
                        anchor: .bottom
                    ) {
                        RestaurantAnnotationView(restaurant: restaurant)
                            .onTapGesture {
                                selectedRestaurant = restaurant
                            }
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .overlay(alignment: .bottom) {
                if let restaurant = selectedRestaurant {
                    RestaurantPreview(restaurant: restaurant)
                        .padding()
                }
            }
            .navigationTitle("Your Restaurants")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                setInitialRegion()
            }
        }
    }
    
    func setInitialRegion() {
        guard !restaurants.isEmpty else { return }
        
        let coordinates = restaurants.map { $0.coordinate }
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}

struct RestaurantAnnotationView: View {
    let restaurant: Restaurant
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 36, height: 36)
                    .shadow(radius: 2)
                
                Circle()
                    .fill(.red)
                    .frame(width: 30, height: 30)
                
                Text("\(restaurant.visits.count)")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.white)
            }
            
            Image(systemName: "triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .offset(y: -3)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Restaurant.self, configurations: config)
    
    // Add sample data
    let restaurant = Restaurant(
        id: "1",
        name: "Sample Restaurant",
        address: "123 Main St",
        latitude: 37.7749,
        longitude: -122.4194
    )
    container.mainContext.insert(restaurant)
    
    return NavigationStack {
        RestaurantMapView()
    }
    .modelContainer(container)
} 