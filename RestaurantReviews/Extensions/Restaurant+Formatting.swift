import Foundation

extension Restaurant {
    var formattedAddress: String {
        var components: [String] = []
        
        // Split the address into its parts
        let parts = address.components(separatedBy: "\n")
        
        // Extract street with number (if present)
        if let streetPart = parts.first {
            components.append(streetPart)
        }
        
        // Extract postcode and city
        let postcodeAndCity = parts.dropFirst().first { part in
            part.contains(" ") && (part.first?.isNumber ?? false)
        }
        if let postcodeAndCity = postcodeAndCity {
            components.append(postcodeAndCity)
        }
        
        // Extract country (usually the last part)
        if let country = parts.last, country != postcodeAndCity {
            components.append(country)
        }
        
        return components.joined(separator: "\n")
    }
} 