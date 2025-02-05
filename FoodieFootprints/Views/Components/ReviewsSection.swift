import SwiftUI
import SwiftData
import PhotosUI

struct ReviewsSection: View {
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
                }
            }
        }
        .sheet(isPresented: $showingAddVisit) {
            AddVisitView(restaurant: restaurant)
        }
        .sheet(item: $visitToEdit) { visit in
            EditVisitView(visit: visit, restaurant: restaurant)
        }
        .alert(String(localized: "Delete Visit"), isPresented: .constant(visitToDelete != nil)) {
            Button(String(localized: "Cancel"), role: .cancel) {
                visitToDelete = nil
            }
            Button(String(localized: "Delete"), role: .destructive) {
                if let visit = visitToDelete,
                   let index = restaurant.visits.firstIndex(where: { $0.id == visit.id }) {
                    restaurant.visits.remove(at: index)
                    modelContext.delete(visit)
                }
                visitToDelete = nil
            }
        } message: {
            Text(String(localized: "Are you sure you want to delete this review? This action cannot be undone."))
        }
        .fullScreenCover(item: Binding(
            get: { selectedPhotoIndex.map { PhotoIdentifier(index: $0) } },
            set: { selectedPhotoIndex = $0?.index }
        )) { identifier in
            PhotoViewer(
                photos: allPhotos,
                initialIndex: identifier.index,
                isPresented: Binding(
                    get: { selectedPhotoIndex },
                    set: { selectedPhotoIndex = $0 }
                )
            )
        }
    }
} 