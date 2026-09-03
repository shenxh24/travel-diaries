import Foundation
import CoreLocation

@MainActor
final class LocationService: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    @Published private(set) var location: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermissionAndStart() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied:
            errorMessage = "定位权限已关闭。请前往“设置 → 隐私与安全性 → 定位服务 → 驻迹”并选择“使用 App 期间”。"
        case .restricted:
            errorMessage = "此设备限制了定位服务，请检查屏幕使用时间或设备管理设置。"
        @unknown default:
            errorMessage = "暂时无法使用定位服务。"
        }
    }

    func requestCurrentLocation() { manager.requestLocation() }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            errorMessage = nil
            manager.startUpdatingLocation()
        } else if manager.authorizationStatus == .denied {
            errorMessage = "定位权限已关闭。请在系统设置中允许驻迹使用位置。"
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newest = locations.last, newest.horizontalAccuracy >= 0 else { return }
        location = newest
        if newest.horizontalAccuracy < 30 { manager.distanceFilter = 25 }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard let locationError = error as? CLError else { errorMessage = error.localizedDescription; return }
        switch locationError.code {
        case .locationUnknown:
            break
        case .denied:
            if manager.authorizationStatus == .denied {
                errorMessage = "定位权限已关闭。请在系统设置中允许驻迹使用位置。"
            }
        default:
            errorMessage = "暂时无法确定位置，请移动到开阔处后重试。"
        }
    }
}
