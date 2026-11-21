
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let locationManager = CLLocationManager()

    @Published private(set) var permissionResolved = false
    @Published var coordinate: CLLocationCoordinate2D?

    @Published private(set) var locationUnavailable = false

    override init() {
        super.init()
        permissionResolved = locationManager.authorizationStatus != .notDetermined
        locationManager.delegate = self
    }

    func requestLocation() {
        locationUnavailable = false
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()

        default:
            locationUnavailable = true
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        permissionResolved = manager.authorizationStatus != .notDetermined
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        } else if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            locationUnavailable = true
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }
        locationUnavailable = false
        coordinate = location.coordinate
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        locationUnavailable = true
    }
}
