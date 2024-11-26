import SwiftUI

struct RestaurantRowView: View {
    let restaurant: Restaurant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(restaurant.name)
                    .font(.headline)
                Spacer()
                RatingView(rating: restaurant.averageRating)
            }
            
            Text(restaurant.formattedAddress)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
            
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
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                Text("\(restaurant.visits.count) visits")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
    }
} 