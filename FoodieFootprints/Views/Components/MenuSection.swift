import SwiftUI

struct MenuSection: View {
    let restaurant: Restaurant
    @Binding var isEditingMenu: Bool
    @Binding var showingPhotoPicker: Bool
    @Binding var selectedMenuFile: MenuFile?
    @Binding var showingFullScreen: Bool
    @Binding var menuFileToDelete: MenuFile?
    @Binding var showingMenuDeleteConfirmation: Bool
    @State private var selectedPhotoIndex: Int?
    
    private struct PhotoIdentifier: Identifiable {
        let index: Int
        var id: Int { index }
    }
    
    var body: some View {
        menuContent
            .fullScreenCover(item: photoViewerBinding) { identifier in
                PhotoViewer(
                    photos: restaurant.menuFiles.map { 
                        Visit.Photo(id: $0.id.uuidString, imageData: $0.data)
                    },
                    initialIndex: identifier.index,
                    isPresented: selectedPhotoBinding
                )
            }
    }
    
    private var menuContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            menuHeader
            menuPhotos
        }
    }
    
    private var menuHeader: some View {
        HStack {
            Text(String(localized: "Menu"))
                .font(.title2)
                .bold()
            Spacer()
            if isEditingMenu {
                addButton
            }
            editButton
        }
        .padding(.horizontal)
    }
    
    private var addButton: some View {
        Button {
            showingPhotoPicker = true
        } label: {
            Label(String(localized: "Add Menu"), systemImage: "plus.circle.fill")
                .foregroundStyle(.pink)
        }
    }
    
    private var editButton: some View {
        Button {
            isEditingMenu.toggle()
        } label: {
            Image(systemName: isEditingMenu ? "checkmark.circle.fill" : "pencil.circle.fill")
                .foregroundStyle(isEditingMenu ? .green : .blue)
        }
    }
    
    private var menuPhotos: some View {
        Group {
            if !restaurant.menuFiles.isEmpty {
                menuPhotoGallery
            } else {
                Text(String(localized: "Add photos of the menu"))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
        }
    }
    
    private var menuPhotoGallery: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(restaurant.menuFiles.enumerated()), id: \.element.id) { index, menuFile in
                    menuPhotoView(menuFile: menuFile, index: index)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func menuPhotoView(menuFile: MenuFile, index: Int) -> some View {
        Group {
            if let image = UIImage(data: menuFile.data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(alignment: .topTrailing) {
                        if isEditingMenu {
                            Button {
                                menuFileToDelete = menuFile
                                showingMenuDeleteConfirmation = true
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .padding(4)
                        }
                    }
                    .onTapGesture {
                        selectedPhotoIndex = index
                    }
            }
        }
    }
    
    private var photoViewerBinding: Binding<PhotoIdentifier?> {
        Binding(
            get: { selectedPhotoIndex.map { PhotoIdentifier(index: $0) } },
            set: { selectedPhotoIndex = $0?.index }
        )
    }
    
    private var selectedPhotoBinding: Binding<Int?> {
        Binding(
            get: { selectedPhotoIndex },
            set: { selectedPhotoIndex = $0 }
        )
    }
} 
