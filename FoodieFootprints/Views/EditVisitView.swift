import SwiftUI
import PhotosUI
import ContactsUI

struct EditVisitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let visit: Visit
    let restaurant: Restaurant
    
    @State private var rating: Double
    @State private var review: String
    @State private var date: Date
    @State private var companions: String
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var photos: [Visit.Photo]
    @State private var isLoading = false
    @State private var showingDeleteConfirmation = false
    @State private var showingContactPicker = false
    
    init(visit: Visit, restaurant: Restaurant) {
        self.visit = visit
        self.restaurant = restaurant
        _rating = State(initialValue: visit.rating)
        _review = State(initialValue: visit.review)
        _date = State(initialValue: visit.date)
        _companions = State(initialValue: visit.companions ?? "")
        _photos = State(initialValue: visit.photos)
    }
    
    private var isValid: Bool {
        !review.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(String(localized: "Visit Date"), selection: $date, displayedComponents: .date)
                    
                    HStack {
                        Text(String(localized: "Rating"))
                        Spacer()
                        RatingControl(rating: $rating)
                    }
                }
                
                Section(String(localized: "Review")) {
                    TextEditor(text: $review)
                        .frame(minHeight: 100)
                }
                
                Section(String(localized: "Companions")) {
                    TextEditor(text: $companions)
                        .frame(minHeight: 100)
                    
                    Button(action: { showingContactPicker = true }) {
                        Label(String(localized: "Add from Contacts"), systemImage: "person.crop.circle.badge.plus")
                    }
                }
                
                Section(String(localized: "Photos")) {
                    PhotosPicker(selection: $selectedItems, matching: .images) {
                        Label(String(localized: "Add More Photos"), systemImage: "photo.on.rectangle.angled")
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
                            Text(String(localized: "Delete Visit"))
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "Edit Visit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Save")) {
                        saveVisit()
                    }
                    .disabled(!isValid)
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
            .alert(String(localized: "Delete Visit"), isPresented: $showingDeleteConfirmation) {
                Button(String(localized: "Cancel"), role: .cancel) { }
                Button(String(localized: "Delete"), role: .destructive) {
                    deleteVisit()
                }
            } message: {
                Text(String(localized: "Are you sure you want to delete this review? This action cannot be undone."))
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPicker(selectedNames: $companions)
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
    
    private func saveVisit() {
        visit.date = date
        visit.rating = rating
        visit.review = review
        visit.companions = companions.isEmpty ? nil : companions
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
