import Foundation
@preconcurrency import CoreLocation

struct AddressResult: Sendable {
    let formatted: String
    let province: String
    let city: String
    let district: String
    let country: String
}

@MainActor
final class GeocodingService {
    private let geocoder = CLGeocoder()

    func reverse(_ coordinate: CLLocationCoordinate2D) async -> AddressResult? {
        do {
            let marks = try await geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), preferredLocale: Locale(identifier: "zh_Hans_CN"))
            guard let mark = marks.first else { return nil }
            let pieces = [mark.administrativeArea, mark.locality, mark.subLocality, mark.thoroughfare, mark.subThoroughfare]
                .compactMap { $0 }.filter { !$0.isEmpty }
            return AddressResult(formatted: pieces.joined(), province: mark.administrativeArea ?? "", city: mark.locality ?? "", district: mark.subLocality ?? "", country: mark.country ?? "")
        } catch { return nil }
    }
}
