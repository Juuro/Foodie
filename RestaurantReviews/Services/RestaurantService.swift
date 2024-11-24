import Foundation
import MapKit

@MainActor
class RestaurantService {
    enum ServiceError: Error, LocalizedError {
        case noResults
        case searchError(Error)
        
        var errorDescription: String? {
            switch self {
            case .noResults:
                return "No restaurants found matching your search"
            case .searchError(let error):
                return "Search failed: \(error.localizedDescription)"
            }
        }
    }
    
    func searchRestaurants(query: String, location: CLLocation? = nil) async throws -> [RestaurantSearchResult] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.pointOfInterestFilter = .init(including: [.restaurant])
        
        if let location {
            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 10000, // 10km radius
                longitudinalMeters: 10000
            )
            request.region = region
        }
        
        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            let results = response.mapItems.map { item -> RestaurantSearchResult in
                let address = formatAddress(from: item.placemark)
                
                return RestaurantSearchResult(
                    id: item.placemark.title ?? UUID().uuidString,
                    name: item.name ?? "Unknown Restaurant",
                    address: address,
                    latitude: item.placemark.coordinate.latitude,
                    longitude: item.placemark.coordinate.longitude,
                    website: item.url?.absoluteString,
                    mapItem: item
                )
            }
            
            guard !results.isEmpty else {
                throw ServiceError.noResults
            }
            
            return results
            
        } catch let error as ServiceError {
            throw error
        } catch {
            throw ServiceError.searchError(error)
        }
    }
    
    private func formatAddress(from placemark: MKPlacemark) -> String {
        var components: [String] = []
        
        // Street and number
        if let street = placemark.thoroughfare {
            if let number = placemark.subThoroughfare {
                components.append("\(street) \(number)")
            } else {
                components.append(street)
            }
        }
        
        // Postcode and city
        var locationPart = ""
        if let postcode = placemark.postalCode {
            locationPart += postcode
        }
        if let city = placemark.locality {
            locationPart += locationPart.isEmpty ? city : " \(city)"
        }
        if !locationPart.isEmpty {
            components.append(locationPart)
        }
        
        // Country
        if let country = placemark.country {
            components.append(country)
        }
        
        return components.isEmpty ? "Address not available" : components.joined(separator: "\n")
    }
} 