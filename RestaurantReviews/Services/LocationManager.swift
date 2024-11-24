import CoreLocation
import SwiftUI

@MainActor
class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var status: LocationStatus = .unknown
    @Published var error: LocationError?
    
    // Configuration options
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyHundredMeters
    var distanceFilter: CLLocationDistance = 100 // meters
    
    enum LocationStatus: String {
        case unknown = "Not Started"
        case noPermission = "Location Access Denied"
        case authorizedWhenInUse = "Location Access Granted"
        case authorizedAlways = "Location Access Always Granted"
        case restricted = "Access Restricted"
        case locationDisabled = "Location Services Disabled"
        case updating = "Updating Location..."
        case error = "Error Getting Location"
    }
    
    enum LocationError: LocalizedError, Equatable {
        case denied
        case disabled
        case restricted
        case unknown(String)
        
        var errorDescription: String? {
            switch self {
            case .denied:
                return "Location access was denied. Please enable it in Settings to use this feature."
            case .disabled:
                return "Location services are disabled. Please enable them in Settings to use this feature."
            case .restricted:
                return "Location access is restricted, possibly due to parental controls."
            case .unknown(let message):
                return "An unexpected error occurred: \(message)"
            }
        }
        
        static func == (lhs: LocationError, rhs: LocationError) -> Bool {
            switch (lhs, rhs) {
            case (.denied, .denied),
                 (.disabled, .disabled),
                 (.restricted, .restricted):
                return true
            case (.unknown(let lhsMessage), .unknown(let rhsMessage)):
                return lhsMessage == rhsMessage
            default:
                return false
            }
        }
    }
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = desiredAccuracy
        manager.distanceFilter = distanceFilter
        checkLocationAuthorization()
    }
    
    func requestLocationPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
        status = .updating
    }
    
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
    
    private func checkLocationAuthorization() {
        switch manager.authorizationStatus {
        case .notDetermined:
            status = .unknown
        case .restricted:
            status = .restricted
            error = .restricted
        case .denied:
            status = .noPermission
            error = .denied
        case .authorizedAlways:
            status = .authorizedAlways
            startUpdatingLocation()
        case .authorizedWhenInUse:
            status = .authorizedWhenInUse
            startUpdatingLocation()
        @unknown default:
            status = .unknown
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            checkLocationAuthorization()
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter out old or inaccurate locations
        let locationAge = -location.timestamp.timeIntervalSinceNow
        guard locationAge < 10,
              location.horizontalAccuracy >= 0,
              location.horizontalAccuracy < 100 else { return }
        
        Task { @MainActor in
            self.location = location
            status = .authorizedWhenInUse
            error = nil
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.error = .denied
                    status = .noPermission
                case .locationUnknown:
                    // Temporary error, keep trying
                    return
                default:
                    self.error = .unknown(error.localizedDescription)
                    status = .error
                }
            } else {
                self.error = .unknown(error.localizedDescription)
                status = .error
            }
        }
    }
}

// SwiftUI View extension for location status banner
extension View {
    func locationStatusBanner(status: LocationManager.LocationStatus, error: LocationManager.LocationError?) -> some View {
        self.overlay(alignment: .top) {
            if let error = error {
                Text(error.localizedDescription)
                    .foregroundStyle(.white)
                    .padding()
                    .background(.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .animation(.default, value: error)
            } else if status == .noPermission || status == .locationDisabled {
                Text(status.rawValue)
                    .foregroundStyle(.white)
                    .padding()
                    .background(.orange)
                    .frame(maxWidth: .infinity)
                    .animation(.default, value: status)
            }
        }
    }
} 