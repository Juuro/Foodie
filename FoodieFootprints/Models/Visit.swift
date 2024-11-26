import Foundation
import SwiftData
import SwiftUI

@Model
final class Visit: Identifiable {
    var id: String
    var date: Date
    var rating: Double
    var review: String
    var photos: [Photo]
    
    init(date: Date, rating: Double, review: String, photos: [Photo] = []) {
        self.id = UUID().uuidString
        self.date = date
        self.rating = rating
        self.review = review
        self.photos = photos
    }
    
    @Model
    final class Photo: Identifiable {
        var id: String
        var imageData: Data
        
        init(id: String = UUID().uuidString, imageData: Data) {
            self.id = id
            self.imageData = imageData
        }
        
        var image: Image? {
            if let uiImage = UIImage(data: imageData) {
                return Image(uiImage: uiImage)
            }
            return nil
        }
    }
} 