import MapKit

struct RestaurantSearchResult: Identifiable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let website: String?
    let mapItem: MKMapItem?
} 