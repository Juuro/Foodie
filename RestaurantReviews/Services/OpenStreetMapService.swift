import Foundation
import CoreLocation

class OpenStreetMapService {
    private let baseURL = "https://nominatim.openstreetmap.org/search"
    
    enum OSMError: Error, LocalizedError {
        case invalidURL
        case networkError(Error)
        case invalidResponse(Int)
        case decodingError(Error)
        case noResults
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL format"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .invalidResponse(let statusCode):
                return "Server error (Status \(statusCode))"
            case .decodingError(let error):
                return "Failed to process response: \(error.localizedDescription)"
            case .noResults:
                return "No restaurants found matching your search"
            }
        }
    }
    
    struct NominatimResponse: Codable {
        let placeId: Int64
        let lat: String
        let lon: String
        let displayName: String
        let type: String?
        let name: String?
        let address: Address?
        
        enum CodingKeys: String, CodingKey {
            case placeId = "place_id"
            case lat, lon
            case displayName = "display_name"
            case type, name
            case address
        }
        
        struct Address: Codable {
            let street: String?
            let houseNumber: String?
            let postcode: String?
            let city: String?
            let country: String?
            
            enum CodingKeys: String, CodingKey {
                case street = "road"
                case houseNumber = "house_number"
                case postcode
                case city
                case country
            }
        }
        
        func toSearchResult() -> RestaurantSearchResult {
            var addressComponents: [String] = []
            
            if let address = address {
                if let street = address.street {
                    if let number = address.houseNumber {
                        addressComponents.append("\(street) \(number)")
                    } else {
                        addressComponents.append(street)
                    }
                }
                
                var locationPart = ""
                if let postcode = address.postcode {
                    locationPart += postcode
                }
                if let city = address.city {
                    locationPart += locationPart.isEmpty ? city : " \(city)"
                }
                if !locationPart.isEmpty {
                    addressComponents.append(locationPart)
                }
                
                if let country = address.country {
                    addressComponents.append(country)
                }
            }
            
            let formattedAddress = addressComponents.isEmpty ? "Address not available" : addressComponents.joined(separator: "\n")
            
            return RestaurantSearchResult(
                id: String(placeId),
                name: name ?? displayName.components(separatedBy: ",").first ?? "Unknown Name",
                address: formattedAddress,
                latitude: Double(lat) ?? 0,
                longitude: Double(lon) ?? 0
            )
        }
    }
    
    func searchRestaurants(query: String, location: CLLocation? = nil) async throws -> [RestaurantSearchResult] {
        var urlComponents = URLComponents(string: baseURL)!
        
        // Build query parameters
        var queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "addressdetails", value: "1"),
            URLQueryItem(name: "category", value: "restaurant"),
            URLQueryItem(name: "limit", value: "50")
        ]
        
        // Add location bias if available
        if let location {
            queryItems.append(contentsOf: [
                URLQueryItem(name: "viewbox", value: createViewbox(around: location)),
                URLQueryItem(name: "bounded", value: "1")
            ])
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw OSMError.invalidURL
        }
        
        var request = URLRequest(url: url)
        // Required by Nominatim usage policy
        request.setValue("RestaurantReviews iOS App", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OSMError.invalidResponse(0)
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw OSMError.invalidResponse(httpResponse.statusCode)
            }
            
            let results = try JSONDecoder().decode([NominatimResponse].self, from: data)
            let searchResults = results
                .filter { $0.type == "restaurant" || $0.type == "cafe" }
                .map { $0.toSearchResult() }
            
            guard !searchResults.isEmpty else {
                throw OSMError.noResults
            }
            
            return searchResults
            
        } catch let error as DecodingError {
            print("Decoding error: \(error)")
            throw OSMError.decodingError(error)
        } catch let error as OSMError {
            print("OSM error: \(error.localizedDescription)")
            throw error
        } catch {
            print("Network error: \(error)")
            throw OSMError.networkError(error)
        }
    }
    
    private func createViewbox(around location: CLLocation, radiusKm: Double = 10) -> String {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        // Approximate 1 degree of latitude/longitude in kilometers
        let latKm = 111.0
        let lonKm = cos(lat * .pi / 180.0) * 111.0
        
        let latDelta = radiusKm / latKm
        let lonDelta = radiusKm / lonKm
        
        let minLon = lon - lonDelta
        let minLat = lat - latDelta
        let maxLon = lon + lonDelta
        let maxLat = lat + latDelta
        
        return "\(minLon),\(minLat),\(maxLon),\(maxLat)"
    }
} 