import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Restaurant.name) private var restaurants: [Restaurant]
    @State private var position: MapCameraPosition = .automatic
    
    var body: some View {
        Map(position: $position) {
            ForEach(restaurants) { restaurant in
                Marker(restaurant.name, coordinate: restaurant.coordinate)
            }
        }
    }
} 