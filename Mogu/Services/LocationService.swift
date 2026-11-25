
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let locationManager = CLLocationManager()

    @Published private(set) var permissionResolved = false
    @Published var coordinate: CLLocationCoordinate2D?

    @Published private(set) var locationUnavailable = false

    //最初の準備
    override init() {
        super.init()
        permissionResolved = locationManager.authorizationStatus != .notDetermined
        locationManager.delegate = self
    }

    func requestLocation() {
        locationUnavailable = false
        //位置情報を使っていいかの確認
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()

        default:
            locationUnavailable = true
        }
    }

    //位置情報への許可の種類が変わった際
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

    //位置情報が取得できない場合
    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        locationUnavailable = true
    }
}
