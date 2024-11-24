import Foundation
import CoreLocation

class YelpService {
    private let apiKey = "LMXRg0WrBFEiiM8SuaazUw3hRp8L3PRAgBeoh7fcOF6WycWpGS8_JGzTv44C9hxqDnTQkjDQQyjzSTRJm_tLtxo9WScGZtIFaM6zc2z7NcxYmYYdJ8b6gDFiWIhDZ3Yx" // Replace with your actual Yelp API key
    private let baseURL = "https://api.yelp.com/v3"
    
    enum YelpError: Error {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case decodingError(Error)
    }
    
    struct YelpResponse: Codable {
        let businesses: [YelpBusiness]
    }
    
    struct YelpBusiness: Codable {
        let id: String
        let name: String
        let location: YelpLocation
        let coordinates: YelpCoordinates
        
        func toSearchResult() -> RestaurantSearchResult {
            RestaurantSearchResult(
                id: id,
                name: name,
                address: location.displayAddress.joined(separator: ", "),
                latitude: coordinates.latitude,
                longitude: coordinates.longitude,
                website: nil,
                mapItem: nil
            )
        }
    }
    
    struct YelpLocation: Codable {
        let displayAddress: [String]
        
        enum CodingKeys: String, CodingKey {
            case displayAddress = "display_address"
        }
    }
    
    struct YelpCoordinates: Codable {
        let latitude: Double
        let longitude: Double
    }
    
    func searchRestaurants(query: String, location: CLLocation? = nil) async throws -> [RestaurantSearchResult] {
        var urlComponents = URLComponents(string: "\(baseURL)/businesses/search")!
        
        var queryItems = [
            URLQueryItem(name: "term", value: query),
            URLQueryItem(name: "categories", value: "restaurants"),
            URLQueryItem(name: "limit", value: "20")
        ]
        
        if let location {
            queryItems.append(contentsOf: [
                URLQueryItem(name: "latitude", value: String(location.coordinate.latitude)),
                URLQueryItem(name: "longitude", value: String(location.coordinate.longitude))
            ])
        } else {
            // Default to a location if none provided
            queryItems.append(URLQueryItem(name: "location", value: "New York"))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw YelpError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw YelpError.invalidResponse
            }
            
            let yelpResponse = try JSONDecoder().decode(YelpResponse.self, from: data)
            return yelpResponse.businesses.map { $0.toSearchResult() }
        } catch let error as DecodingError {
            throw YelpError.decodingError(error)
        } catch {
            throw YelpError.networkError(error)
        }
    }
} 
