import Foundation
import CoreLocation

struct WeatherStamp: Sendable {
    let temperature: Double
    let condition: String
}

actor WeatherService {
    private struct Response: Decodable { let current: Current }
    private struct Current: Decodable { let temperature_2m: Double; let weather_code: Int }

    func current(at coordinate: CLLocationCoordinate2D) async -> WeatherStamp? {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code")
        ]
        guard let url = components.url,
              let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let value = try? JSONDecoder().decode(Response.self, from: data) else { return nil }
        return WeatherStamp(temperature: value.current.temperature_2m, condition: condition(value.current.weather_code))
    }

    private func condition(_ code: Int) -> String {
        switch code {
        case 0: "晴"
        case 1...3: "多云"
        case 45...48: "有雾"
        case 51...67, 80...82: "有雨"
        case 71...77, 85...86: "有雪"
        case 95...99: "雷雨"
        default: "天气未知"
        }
    }
}

