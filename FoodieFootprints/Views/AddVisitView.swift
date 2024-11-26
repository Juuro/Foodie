import SwiftUI
import PhotosUI

struct AddVisitView: View {
    @Environment(\.dismiss) private var dismiss
    let restaurant: Restaurant
    
    @State private var rating: Double = 3
    @State private var review = ""
    @State private var date = Date()
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var photos: [Visit.Photo] = []
    @State private var isLoading = false
    
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
                        Label("Select Photos", systemImage: "photo.on.rectangle.angled")
                    }
                    
                    if !photos.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(photos, id: \.id) { photo in
                                    if let image = photo.image {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveVisit()
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
        }
    }
    
    private func loadPhotos() async {
        isLoading = true
        photos = []
        
        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self) {
                photos.append(Visit.Photo(imageData: data))
            }
        }
        
        isLoading = false
    }
    
    private func saveVisit() {
        let visit = Visit(
            date: date,
            rating: rating,
            review: review,
            photos: photos
        )
        restaurant.visits.append(visit)
        dismiss()
    }
}

struct RatingControl: View {
    @Binding var rating: Double
    
    var body: some View {
        HStack {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= Int(rating) ? "star.fill" : "star")
                    .foregroundStyle(.yellow)
                    .onTapGesture {
                        withAnimation {
                            rating = Double(index)
                        }
                    }
            }
        }
    }
} 