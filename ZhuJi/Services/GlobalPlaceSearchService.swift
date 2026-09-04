import Foundation

struct GlobalPlaceResult: Sendable {
    let name: String, displayName: String, country: String, state: String, city: String, district: String
    let latitude: Double, longitude: Double
}

actor GlobalPlaceSearchService {
    private struct APIResult: Decodable {
        struct Address: Decodable {
            let country: String?, state: String?, city: String?, town: String?, municipality: String?, county: String?, suburb: String?
        }
        let lat: String, lon: String, display_name: String, name: String?, address: Address?
    }
    private var lastRequestAt = Date.distantPast
    private var cache: [String: [GlobalPlaceResult]] = [:]

    func search(_ query: String) async throws -> [GlobalPlaceResult] {
        let key = query.lowercased()
        if let cached = cache[key] { return cached }
        let elapsed = Date().timeIntervalSince(lastRequestAt)
        if elapsed < 1 { try await Task.sleep(for: .seconds(1 - elapsed)) }
        var parts = URLComponents(string: "https://nominatim.openstreetmap.org/search")!
        parts.queryItems = [URLQueryItem(name: "q", value: query), URLQueryItem(name: "format", value: "jsonv2"), URLQueryItem(name: "addressdetails", value: "1"), URLQueryItem(name: "limit", value: "8"), URLQueryItem(name: "accept-language", value: "zh-CN,en")]
        guard let url = parts.url else { return [] }
        var request = URLRequest(url: url)
        request.setValue("ZhuJi/1.0 (com.xhshen.traveldiary)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 12
        lastRequestAt = .now
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }
        let decoded = try JSONDecoder().decode([APIResult].self, from: data)
        let values = decoded.compactMap { value -> GlobalPlaceResult? in
            guard let lat = Double(value.lat), let lon = Double(value.lon) else { return nil }
            let address = value.address
            return GlobalPlaceResult(name: value.name ?? value.display_name.components(separatedBy: ",").first ?? "未命名地点", displayName: value.display_name, country: address?.country ?? "", state: address?.state ?? "", city: address?.city ?? address?.town ?? address?.municipality ?? "", district: address?.suburb ?? address?.county ?? "", latitude: lat, longitude: lon)
        }
        cache[key] = values
        return values
    }
}
