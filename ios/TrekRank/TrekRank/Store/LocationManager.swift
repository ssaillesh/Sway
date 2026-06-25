import Foundation
import CoreLocation
import Combine

/// Wraps CoreLocation to publish the device's live GPS position and the current
/// authorization status. Used by the Map screen to show "you are here".
@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published var location: CLLocationCoordinate2D?
    @Published var authorization: CLAuthorizationStatus

    private let manager = CLLocationManager()

    override init() {
        authorization = manager.authorizationStatus
        super.init()
        manager.delegate = self
        // A "you are here" dot doesn't need pinpoint accuracy. Best-accuracy GPS
        // plus compass heading ran the location/sensor stack continuously, which
        // added heat with no UI benefit — heading wasn't used anywhere.
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 50 // meters
    }

    /// Ask for permission (if needed) and start streaming updates.
    func start() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
    }

    var isAuthorized: Bool {
        authorization == .authorizedWhenInUse || authorization == .authorizedAlways
    }

    var isDenied: Bool {
        authorization == .denied || authorization == .restricted
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorization = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        let coord = loc.coordinate
        Task { @MainActor in self.location = coord }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Non-fatal: keep last known location.
    }
}
