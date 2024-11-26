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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(restaurant.allPhotos.prefix(3), id: \.id) { photo in
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