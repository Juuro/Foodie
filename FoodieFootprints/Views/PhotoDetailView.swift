import SwiftUI

struct PhotoDetailView: View {
    let photo: Visit.Photo
    
    var body: some View {
        if let image = photo.image {
            image
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()
        }
    }
} 