import SwiftUI
import PhotosUI

struct EditVisitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let visit: Visit
    let restaurant: Restaurant
    
    @State private var rating: Double
    @State private var review: String
    @State private var date: Date
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var photos: [Visit.Photo]
    @State private var isLoading = false
    @State private var showingDeleteConfirmation = false
    
    init(visit: Visit, restaurant: Restaurant) {
        self.visit = visit
        self.restaurant = restaurant
        _rating = State(initialValue: visit.rating)
        _review = State(initialValue: visit.review)
        _date = State(initialValue: visit.date)
        _photos = State(initialValue: visit.photos)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Visit Date", selection: $date, displayedComponents: .date)
                    
                    HStack {
                        Text("Rating")
                        Spacer()
                        RatingControl(rating: $rating)
                    }
                }
                
                Section("Review") {
                    TextEditor(text: $review)
                        .frame(minHeight: 100)
                }
                
                Section("Photos") {
                    PhotosPicker(selection: $selectedItems, matching: .images) {
                        Label("Add More Photos", systemImage: "photo.on.rectangle.angled")
                    }
                    
                    if !photos.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(photos) { photo in
                                    if let image = photo.image {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(alignment: .topTrailing) {
                                                Button {
                                                    removePhoto(photo)
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundStyle(.white)
                                                        .background(Color.black.opacity(0.5))
                                                        .clipShape(Circle())
                                                }
                                                .padding(4)
                                            }
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Visit")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
            .onChange(of: selectedItems) {
                Task {
                    await loadPhotos()
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .background(.ultraThinMaterial)
                }
            }
            .alert("Delete Visit", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteVisit()
                }
            } message: {
                Text("Are you sure you want to delete this visit? This action cannot be undone.")
            }
        }
    }
    
    private func loadPhotos() async {
        isLoading = true
        
        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self) {
                photos.append(Visit.Photo(imageData: data))
            }
        }
        
        selectedItems = []
        isLoading = false
    }
    
    private func removePhoto(_ photo: Visit.Photo) {
        photos.removeAll { $0.id == photo.id }
    }
    
    private func saveChanges() {
        visit.date = date
        visit.rating = rating
        visit.review = review
        visit.photos = photos
        dismiss()
    }
    
    private func deleteVisit() {
        if let index = restaurant.visits.firstIndex(where: { $0.id == visit.id }) {
            restaurant.visits.remove(at: index)
            modelContext.delete(visit)
        }
        dismiss()
    }
} 