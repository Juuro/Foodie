import SwiftUI
import MapKit
import SwiftData
import PhotosUI

struct RestaurantDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddVisit = false
    @State private var showingDeleteConfirmation = false
    @State private var showingPhotoPicker = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedMenuFile: MenuFile?
    @State private var showingFullScreen = false
    @State private var isEditingMenu = false
    @State private var menuFileToDelete: MenuFile?
    @State private var showingMenuDeleteConfirmation = false
    @State private var selectedPhotoIndex: Int?
    let restaurant: Restaurant
    
    private let gridSpacing: CGFloat = 12
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var happyCowURL: URL? {
        var components = URLComponents(string: "https://www.happycow.net/searchmap")
        components?.queryItems = [
            URLQueryItem(name: "location", value: "\(restaurant.latitude),\(restaurant.longitude)"),
            URLQueryItem(name: "keyword", value: restaurant.name)
        ]
        return components?.url
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with name and average rating
                HStack {
                    Text(restaurant.name)
                        .font(.title)
                        .bold()
                    Spacer()
                    RatingView(rating: restaurant.averageRating)
                }
                .padding(.horizontal)
                
                // Recent photos
                if !restaurant.allPhotos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(restaurant.allPhotos.enumerated()), id: \.element.id) { index, photo in
                                if let image = photo.image {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .onTapGesture {
                                            selectedPhotoIndex = index
                                        }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
                
                // Map preview
                MapPreview(restaurant: restaurant)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                
                // Visit count and address
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock.fill")
                        Text("\(restaurant.visits.count) \(String(localized: "visits"))")
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "location.fill")
                        Text(restaurant.formattedAddress)
                            .lineSpacing(4)
                            .textSelection(.enabled)
                    }
                    
                    if let websiteString = restaurant.website,
                       let url = URL(string: websiteString) {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "globe")
                                Text(String(localized: "Visit Website"))
                            }
                        }
                    }
                    
                    if let url = happyCowURL {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "link")
                                Text(String(localized: "View on HappyCow"))
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Menu photos section
                MenuSection(
                    restaurant: restaurant,
                    isEditingMenu: $isEditingMenu,
                    showingPhotoPicker: $showingPhotoPicker,
                    selectedMenuFile: $selectedMenuFile,
                    showingFullScreen: $showingFullScreen,
                    menuFileToDelete: $menuFileToDelete,
                    showingMenuDeleteConfirmation: $showingMenuDeleteConfirmation
                )
                
                // Reviews section
                ReviewsSection(restaurant: restaurant, visits: restaurant.visits.sorted { $0.date > $1.date })
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: { showingAddVisit = true }) {
                        Label(String(localized: "Add Visit"), systemImage: "plus")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label(String(localized: "Delete Restaurant"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddVisit) {
            AddVisitView(restaurant: restaurant)
        }
        .alert(String(localized: "Delete Restaurant"), isPresented: $showingDeleteConfirmation) {
            Button(String(localized: "Cancel"), role: .cancel) { }
            Button(String(localized: "Delete"), role: .destructive) {
                deleteRestaurant()
            }
        } message: {
            if restaurant.visits.isEmpty {
                Text("Are you sure you want to delete this restaurant?")
            } else {
                Text(String(format: String(localized: "Are you sure you want to delete this restaurant? This will also delete all %lld reviews. This action cannot be undone."), restaurant.visits.count))
            }
        }
        .photosPicker(isPresented: $showingPhotoPicker,
                     selection: $selectedItems,
                     matching: .images)
        .onChange(of: selectedItems) { oldValue, newValue in
            if !newValue.isEmpty {
                Task {
                    await loadMenuPhotos()
                }
            }
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
            if let menuFile = selectedMenuFile {
                MenuFileViewer(menuFile: menuFile) {
                    if let index = restaurant.menuFiles.firstIndex(where: { $0.id == menuFile.id }) {
                        restaurant.menuFiles.remove(at: index)
                    }
                }
            }
        }
        .alert(String(localized: "Delete Menu Photo"), isPresented: $showingMenuDeleteConfirmation) {
            Button(String(localized: "Cancel"), role: .cancel) { }
            Button(String(localized: "Delete"), role: .destructive) {
                if let menuFile = menuFileToDelete {
                    if let index = restaurant.menuFiles.firstIndex(where: { $0.id == menuFile.id }) {
                        restaurant.menuFiles.remove(at: index)
                    }
                }
            }
        } message: {
            Text(String(localized: "Are you sure you want to delete this menu photo?"))
        }
        .fullScreenCover(item: Binding(
            get: { selectedPhotoIndex.map { PhotoIdentifier(index: $0) } },
            set: { selectedPhotoIndex = $0?.index }
        )) { identifier in
            PhotoViewer(
                photos: restaurant.allPhotos,
                initialIndex: identifier.index,
                isPresented: Binding(
                    get: { selectedPhotoIndex },
                    set: { selectedPhotoIndex = $0 }
                )
            )
        }
    }
    
    private func deleteRestaurant() {
        // First delete all visits
        for visit in restaurant.visits {
            modelContext.delete(visit)
        }
        // Then delete the restaurant
        modelContext.delete(restaurant)
        dismiss()
    }
    
    private func loadMenuPhotos() async {
        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let menuFile = MenuFile(
                    name: "Menu Photo \(restaurant.menuFiles.count + 1)",
                    data: data,
                    type: "image"
                )
                restaurant.menuFiles.append(menuFile)
            }
        }
        selectedItems = []
    }
    
    private struct PhotoIdentifier: Identifiable {
        let index: Int
        var id: Int { index }
    }
}