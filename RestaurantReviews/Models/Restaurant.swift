import Foundation
import SwiftData
import CoreLocation
import MapKit

@Model
final class Restaurant: Identifiable {
    var id: String
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var visits: [Visit]
    
    init(id: String, name: String, address: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.visits = []
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var averageRating: Double {
        guard !visits.isEmpty else { return 0 }
        return visits.reduce(0.0) { $0 + $1.rating } / Double(visits.count)
    }
    
    var recentPhotos: [Visit.Photo] {
        Array(visits.flatMap { $0.photos }.prefix(3))
    }
} 