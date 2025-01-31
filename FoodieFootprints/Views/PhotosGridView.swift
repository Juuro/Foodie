import SwiftUI

struct PhotosGridView: View {
    let photos: [Visit.Photo]
    @State private var selectedPhotoIndex: Int?
    
    private struct PhotoIdentifier: Identifiable {
        let index: Int
        var id: Int { index }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: [GridItem(.fixed(100))], spacing: 8) {
                ForEach(photos.indices, id: \.self) { index in
                    Button {
                        selectedPhotoIndex = index
                    } label: {
                        PhotoThumbnail(photo: photos[index])
                    }
                }
            }
            .padding(.horizontal)
        }
        .sheet(item: Binding(
            get: { selectedPhotoIndex.map(PhotoIdentifier.init) },
            set: { selectedPhotoIndex = $0?.index }
        )) { identifier in
            NavigationStack {
                PhotoDetailView(photo: photos[identifier.index])
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(String(localized: "Done")) {
                                selectedPhotoIndex = nil
                            }
                        }
                    }
            }
        }
    }
} 