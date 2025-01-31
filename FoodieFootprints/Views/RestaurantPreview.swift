import SwiftUI

struct RestaurantPreview: View {
    let restaurant: Restaurant
    let onDelete: (() -> Void)?
    
    init(restaurant: Restaurant, onDelete: (() -> Void)? = nil) {
        self.restaurant = restaurant
        self.onDelete = onDelete
    }
    
    var body: some View {
        
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(restaurant.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    RatingView(rating: restaurant.averageRating)
                }
                
                Text(restaurant.formattedAddress)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .foregroundColor(.primary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                
                if !restaurant.allPhotos.isEmpty {
                    GeometryReader { geometry in
                        let photoCount = Int(geometry.size.width / 68) // 60 for photo + 8 for spacing
                        HStack(spacing: 8) {
                            ForEach(Array(restaurant.allPhotos.prefix(photoCount).enumerated()), id: \.element.id) { index, photo in
                                if let image = photo.image {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .opacity(index == photoCount - 1 && restaurant.allPhotos.count > photoCount ? 0.3 : 1.0)
                                        .overlay {
                                            if index == photoCount - 1 && restaurant.allPhotos.count > photoCount {
                                                Text("+\(restaurant.allPhotos.count - photoCount)")
                                                    .font(.headline)
                                                    .foregroundStyle(.white)
                                                    .padding(4)
                                                    .background(.black.opacity(0.6))
                                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .frame(height: 60)
                }
                
                HStack {
                    if !restaurant.visits.isEmpty {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                            .foregroundColor(.primary)
                        Text("\(restaurant.visits.count) \(String(localized: "visits"))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .foregroundColor(.primary)
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
            
        }
        .buttonStyle(.plain)
        .modifier(SwipeActionsModifier(onDelete: onDelete))
    }
}

private struct SwipeActionsModifier: ViewModifier {
    let onDelete: (() -> Void)?
    
    func body(content: Content) -> some View {
        if let onDelete = onDelete {
            content.swipeActions(edge: .trailing) {
                Button(role: .destructive, action: onDelete) {
                    Label(String(localized: "Delete"), systemImage: "trash")
                }
            }
        } else {
            content
        }
    }
} 
