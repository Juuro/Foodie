import SwiftUI
import MapKit

struct RestaurantDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddVisit = false
    let restaurant: Restaurant
    
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
                Button(action: { showingAddVisit = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddVisit) {
            AddVisitView(restaurant: restaurant)
        }
    }
}

private struct PhotosGridView: View {
    let photos: [Visit.Photo]
    @State private var selectedPhoto: Visit.Photo?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(photos, id: \.id) { photo in
                    if let image = photo.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 280, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture {
                                selectedPhoto = photo
                            }
                    }
                }
            }
            .padding(.horizontal)
        }
        .sheet(item: $selectedPhoto) { photo in
            if let image = photo.image {
                image
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
            }
        }
    }
}

private struct MapPreview: View {
    let restaurant: Restaurant
    @State private var cameraPosition: MapCameraPosition
    
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
    }
    
    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: restaurant.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = restaurant.name
        mapItem.openInMaps()
    }
}

private struct ReviewsSection: View {
    @Environment(\.modelContext) private var modelContext
    let restaurant: Restaurant
    let visits: [Visit]
    @State private var visitToEdit: Visit?
    @State private var visitToDelete: Visit?
    @State private var showingAddVisit = false
    
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
                ForEach(Array(visits.enumerated()), id: \.element.id) { _, visit in
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
                                    ForEach(visit.photos) { photo in
                                        if let image = photo.image {
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 60, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
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
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            visitToDelete = visit
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
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