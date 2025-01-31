import SwiftUI

struct PhotoThumbnail: View {
    let photo: Visit.Photo
    
    var body: some View {
        if let image = photo.image {
            image
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
} 