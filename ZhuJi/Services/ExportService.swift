import Foundation

struct ExportCheckIn: Codable {
    let id: UUID, title: String, diary: String, category: String, address: String
    let latitude: Double, longitude: Double, createdAt: Date
    let temperature: Double?, weatherCondition: String?, photos: [String]
}

enum ExportService {
    static func createJSON(_ items: [CheckIn]) throws -> URL {
        let payload = items.map { ExportCheckIn(id: $0.id, title: $0.title, diary: $0.diary, category: $0.categoryRawValue, address: $0.address, latitude: $0.latitude, longitude: $0.longitude, createdAt: $0.createdAt, temperature: $0.temperature, weatherCondition: $0.weatherCondition, photos: $0.photos.map(\.fileName)) }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
        let url = FileManager.default.temporaryDirectory.appending(path: "驻迹备份-\(Date.now.formatted(.iso8601.year().month().day())).json")
        try encoder.encode(payload).write(to: url, options: .atomic)
        return url
    }
}

