import SwiftUI
import MapKit

struct RestaurantDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddVisit = false
    @State private var showingDeleteConfirmation = false
    let restaurant: Restaurant
    
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
                if !restaurant.recentPhotos.isEmpty {
                    PhotosGridView(photos: restaurant.recentPhotos)
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
                            .foregroundStyle(.secondary)
                        Text("\(restaurant.visits.count) visits")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.secondary)
                        Text(restaurant.formattedAddress)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                            .textSelection(.enabled)
                    }
                    
                    if let websiteString = restaurant.website,
                       let url = URL(string: websiteString) {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundStyle(.secondary)
                                Text("Visit Website")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    if let url = happyCowURL {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "link")
                                    .foregroundStyle(.secondary)
                                Text("View on HappyCow")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
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
                        Label("Add Review", systemImage: "plus")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Restaurant", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddVisit) {
            AddVisitView(restaurant: restaurant)
        }
        .alert("Delete Restaurant", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteRestaurant()
            }
        } message: {
            if restaurant.visits.isEmpty {
                Text("Are you sure you want to delete this restaurant?")
            } else {
                Text("Are you sure you want to delete this restaurant? This will also delete all \(restaurant.visits.count) reviews. This action cannot be undone.")
            }
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
}

private struct PhotosGridView: View {
    let photos: [Visit.Photo]
    @State private var selectedPhotoIndex: Int?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    if let image = photo.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 280, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture {
                                selectedPhotoIndex = index
                            }
                    }
                }
            }
            .padding(.horizontal)
        }
        .fullScreenCover(item: Binding(
            get: { selectedPhotoIndex.map { PhotoIdentifier(index: $0) } },
            set: { selectedPhotoIndex = $0?.index }
        )) { identifier in
            PhotoViewer(photos: photos, initialIndex: identifier.index, isPresented: $selectedPhotoIndex)
        }
    }
    
    private struct PhotoIdentifier: Identifiable {
        let index: Int
        var id: Int { index }
    }
}

private struct PhotoViewer: View {
    let photos: [Visit.Photo]
    let initialIndex: Int
    @Binding var isPresented: Int?
    @State private var currentIndex: Int
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    
    init(photos: [Visit.Photo], initialIndex: Int, isPresented: Binding<Int?>) {
        self.photos = photos
        self.initialIndex = initialIndex
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        GeometryReader { geometry in
            TabView(selection: $currentIndex) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                    if let image = photo.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .tag(index)
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = value
                                    }
                                    .onEnded { _ in
                                        withAnimation {
                                            scale = 1.0
                                        }
                                    }
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        offset = value.translation
                                    }
                                    .onEnded { value in
                                        withAnimation {
                                            let height = value.translation.height
                                            if abs(height) > 100 {
                                                isPresented = nil
                                            } else {
                                                offset = .zero
                                            }
                                        }
                                    }
                            )
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
        .background(.black)
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            Button {
                isPresented = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .padding()
            }
        }
        .overlay(alignment: .bottom) {
            Text("\(currentIndex + 1) of \(photos.count)")
                .foregroundStyle(.white)
                .padding()
        }
    }
}

private struct MapPreview: View {
    let restaurant: Restaurant
    @State private var cameraPosition: MapCameraPosition
    @State private var mapItem: MKMapItem?
    
    init(restaurant: Restaurant) {
        self.restaurant = restaurant
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: restaurant.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }
    
    var body: some View {
        Map(position: $cameraPosition) {
            Annotation(
                restaurant.name,
                coordinate: restaurant.coordinate
            ) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.title)
                    .foregroundStyle(.red)
            }
        }
        .overlay(alignment: .bottomTrailing) {
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
            
            // Find the closest match
            let closestItem = response.mapItems.min { item1, item2 in
                let distance1 = item1.placemark.coordinate.distance(to: restaurant.coordinate)
                let distance2 = item2.placemark.coordinate.distance(to: restaurant.coordinate)
                return distance1 < distance2
            }
            
            if let item = closestItem {
                mapItem = item
            }
        } catch {
            print("Failed to find map item: \(error)")
        }
    }
    
    private func openInMaps() {
        if let mapItem = mapItem {
            mapItem.openInMaps()
        } else {
            // Fallback to simple coordinates if we couldn't find the place
            let placemark = MKPlacemark(coordinate: restaurant.coordinate)
            let fallbackItem = MKMapItem(placemark: placemark)
            fallbackItem.name = restaurant.name
            fallbackItem.openInMaps()
        }
    }
}

// Add extension to help calculate distances between coordinates
extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let this = CLLocation(latitude: latitude, longitude: longitude)
        let that = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return this.distance(from: that)
    }
}

private struct ReviewsSection: View {
    @Environment(\.modelContext) private var modelContext
    let restaurant: Restaurant
    let visits: [Visit]
    @State private var visitToEdit: Visit?
    @State private var visitToDelete: Visit?
    @State private var showingAddVisit = false
    @State private var selectedPhotoIndex: Int?
    
    private struct PhotoIdentifier: Identifiable {
        let index: Int
        var id: Int { index }
    }
    
    // Get all photos from all visits in order
    var allPhotos: [Visit.Photo] {
        visits.flatMap { $0.photos }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Reviews")
                    .font(.title2)
                    .bold()
                Spacer()
                Button {
                    showingAddVisit = true
                } label: {
                    Label("Add Review", systemImage: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal)
            
            LazyVStack(spacing: 16) {
                ForEach(visits) { visit in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            RatingView(rating: visit.rating)
                            Spacer()
                            Text(visit.date.formatted(date: .abbreviated, time: .omitted))
                                .foregroundStyle(.secondary)
                            Menu {
                                Button(role: .destructive) {
                                    visitToDelete = visit
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    visitToEdit = visit
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundStyle(.blue)
                            }
                        }
                        
                        if !visit.review.isEmpty {
                            Text(visit.review)
                                .font(.body)
                        }
                        
                        if !visit.photos.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(visit.photos.enumerated()), id: \.element.id) { index, photo in
                                        if let image = photo.image {
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 60, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .onTapGesture {
                                                    // Calculate global index for this photo
                                                    let globalIndex = allPhotos.firstIndex(where: { $0.id == photo.id }) ?? 0
                                                    selectedPhotoIndex = globalIndex
                                                }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            visitToDelete = visit
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            visitToEdit = visit
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddVisit) {
            AddVisitView(restaurant: restaurant)
        }
        .sheet(item: $visitToEdit) { visit in
            EditVisitView(visit: visit, restaurant: restaurant)
        }
        .alert("Delete Visit", isPresented: .constant(visitToDelete != nil)) {
            Button("Cancel", role: .cancel) {
                visitToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let visit = visitToDelete {
                    deleteVisit(visit)
                }
                visitToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this visit? This action cannot be undone.")
        }
        .fullScreenCover(item: Binding(
            get: { selectedPhotoIndex.map { PhotoIdentifier(index: $0) } },
            set: { selectedPhotoIndex = $0?.index }
        )) { identifier in
            PhotoViewer(photos: allPhotos, initialIndex: identifier.index, isPresented: $selectedPhotoIndex)
        }
    }
    
    private func deleteVisit(_ visit: Visit) {
        if let index = restaurant.visits.firstIndex(where: { $0.id == visit.id }) {
            restaurant.visits.remove(at: index)
            modelContext.delete(visit)
        }
    }
}

#Preview {
    NavigationStack {
        RestaurantDetailView(restaurant: Restaurant(
            id: "1",
            name: "Sample Restaurant",
            address: "123 Main St",
            latitude: 37.7749,
            longitude: -122.4194
        ))
    }
    .modelContainer(for: Restaurant.self)
} 