import SwiftUI
import MapKit
import SwiftData
import PhotosUI
import ContactsUI

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
                    PhotosGridView(photos: restaurant.allPhotos)
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
}

private struct PhotoViewer: View {
    let photos: [Visit.Photo]
    let initialIndex: Int
    @Binding var isPresented: Int?
    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
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
                        GeometryReader { proxy in
                            image
                                .resizable()
                                .scaledToFit()
                                .tag(index)
                                .scaleEffect(scale)
                                .offset(offset)
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            let delta = value / lastScale
                                            lastScale = value
                                            scale *= delta
                                        }
                                        .onEnded { _ in
                                            lastScale = 1.0
                                        }
                                )
                                .frame(
                                    width: proxy.size.width,
                                    height: proxy.size.height
                                )
                        }
                    }
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page)
            .onChange(of: currentIndex) {
                // Reset zoom when changing photos
                scale = 1.0
                lastScale = 1.0
                offset = .zero
            }
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

private extension String {
    func findContact() async -> CNContact? {
        return await Task.detached {
            let store = CNContactStore()
            let keysToFetch: [CNKeyDescriptor] = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactViewController.descriptorForRequiredKeys() as CNKeyDescriptor
            ]
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            
            var matchingContact: CNContact?
            try? store.enumerateContacts(with: request) { contact, _ in
                let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                if self == fullName {
                    matchingContact = contact
                }
            }
            return matchingContact
        }.value
    }
}

private struct CompanionsView: View {
    let companions: String
    
    var body: some View {
        let names = companions.components(separatedBy: ", ")
        FlowLayout(spacing: 4) {
            ForEach(Array(names.enumerated()), id: \.element) { index, name in
                HStack(spacing: 4) {
                    CompanionButton(name: name)
                    if index < names.count - 1 {
                        Text("·")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 4) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var position = CGPoint.zero
        var maxHeight: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        // Calculate height
        for size in sizes {
            if position.x + size.width > (proposal.width ?? .infinity) {
                position.x = 0
                position.y += lineHeight + spacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            position.x += size.width + spacing
            maxHeight = max(maxHeight, position.y + lineHeight)
        }
        
        return CGSize(width: proposal.width ?? .infinity, height: maxHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var position = CGPoint(x: bounds.minX, y: bounds.minY)
        var lineHeight: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            
            if position.x + size.width > bounds.maxX {
                position.x = bounds.minX
                position.y += lineHeight + spacing
                lineHeight = 0
            }
            
            subview.place(
                at: CGPoint(x: position.x, y: position.y),
                proposal: ProposedViewSize(size)
            )
            
            lineHeight = max(lineHeight, size.height)
            position.x += size.width + spacing
        }
    }
}

private struct CompanionButton: View {
    let name: String
    @State private var contact: CNContact?
    @State private var isContactLoaded = false
    
    var body: some View {
        Group {
            if isContactLoaded && contact != nil {
                Button(action: {
                    openContact(contact: contact!)
                }) {
                    Text(name)
                        .foregroundStyle(.blue)
                }
            } else {
                Text(name)
            }
        }
        .font(.subheadline)
        .task {
            contact = await name.findContact()
            isContactLoaded = true
        }
    }
    
    private func openContact(contact: CNContact) {
        let contactVC = CNContactViewController(for: contact)
        contactVC.allowsEditing = false
        contactVC.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { _ in
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    rootVC.dismiss(animated: true)
                }
            }
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            let navController = UINavigationController(rootViewController: contactVC)
            rootVC.present(navController, animated: true)
        }
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
                Text(String(localized: "Visits"))
                    .font(.title2)
                    .bold()
                Spacer()
                Button {
                    showingAddVisit = true
                } label: {
                    Label(String(localized: "Add Visit"), systemImage: "plus.circle.fill")
                        .foregroundStyle(.pink)
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
                        
                        if let companions = visit.companions, !companions.isEmpty {
                            CompanionsView(companions: companions)
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
