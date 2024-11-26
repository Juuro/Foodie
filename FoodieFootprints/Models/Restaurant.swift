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
    var website: String?
    var createdAt: Date
    
    init(id: String, name: String, address: String, latitude: Double, longitude: Double, website: String? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.website = website
        self.visits = []
        self.createdAt = Date()
    }
    
    init(from previous: Restaurant) {
        self.id = previous.id
        self.name = previous.name
        self.address = previous.address
        self.latitude = previous.latitude
        self.longitude = previous.longitude
        self.website = previous.website
        self.visits = previous.visits
        self.createdAt = Date.distantPast
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var averageRating: Double {
        guard !visits.isEmpty else { return 0 }
        return visits.reduce(0.0) { $0 + $1.rating } / Double(visits.count)
    }
    
    var allPhotos: [Visit.Photo] {
        visits
            .sorted { $0.date > $1.date }
            .flatMap { $0.photos }
    }
} 