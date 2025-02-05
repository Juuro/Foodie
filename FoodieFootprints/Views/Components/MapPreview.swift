import SwiftUI
import MapKit

struct MapPreview: View {
    let restaurant: Restaurant
    @State private var mapItem: MKMapItem?
    
    var body: some View {
        Map(coordinateRegion: .constant(MKCoordinateRegion(
            center: restaurant.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
        .overlay(alignment: .topTrailing) {
            Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)
                .padding(8)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            openInMaps()
        }
        .task {
            await findMapItem()
        }
    }
    
    private func openInMaps() {
        if let mapItem = mapItem {
            mapItem.openInMaps()
        } else {
            let placemark = MKPlacemark(coordinate: restaurant.coordinate)
            let fallbackItem = MKMapItem(placemark: placemark)
            fallbackItem.name = restaurant.name
            fallbackItem.openInMaps()
        }
    }
    
    private func findMapItem() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = restaurant.name
        request.region = MKCoordinateRegion(
            center: restaurant.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            mapItem = response.mapItems.min { item1, item2 in
                let distance1 = item1.placemark.coordinate.distance(to: restaurant.coordinate)
                let distance2 = item2.placemark.coordinate.distance(to: restaurant.coordinate)
                return distance1 < distance2
            }
        } catch {
            print("Failed to find map item: \(error)")
        }
    }
}

// Add the coordinate extension here
extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let this = CLLocation(latitude: latitude, longitude: longitude)
        let that = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return this.distance(from: that)
    }
} 