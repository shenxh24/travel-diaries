import Foundation
import SwiftData
import CoreLocation

enum PlaceCategory: String, Codable, CaseIterable, Identifiable {
    case food = "美食"
    case sightseeing = "景点"
    case city = "城市"
    case shopping = "购物"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .food: "fork.knife"
        case .sightseeing: "camera.fill"
        case .city: "building.2.fill"
        case .shopping: "bag.fill"
        }
    }
}

@Model
final class CheckIn {
    @Attribute(.unique) var id: UUID
    var title: String
    var diary: String
    var categoryRawValue: String
    var latitude: Double
    var longitude: Double
    var address: String
    var province: String
    var city: String
    var district: String
    var country: String = ""
    var createdAt: Date
    var updatedAt: Date
    var temperature: Double?
    var weatherCondition: String?
    var featuredPhotoID: UUID?
    @Relationship(deleteRule: .cascade, inverse: \TravelPhoto.checkIn)
    var photos: [TravelPhoto]

    var category: PlaceCategory {
        get { PlaceCategory(rawValue: categoryRawValue) ?? .sightseeing }
        set { categoryRawValue = newValue.rawValue }
    }
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    var featuredPhoto: TravelPhoto? {
        if let featuredPhotoID, let selected = photos.first(where: { $0.id == featuredPhotoID }) { return selected }
        return photos.first
    }

    init(title: String = "新的足迹", diary: String = "", category: PlaceCategory = .sightseeing,
         latitude: Double, longitude: Double, address: String = "正在获取地址…", createdAt: Date = .now) {
        self.id = UUID(); self.title = title; self.diary = diary
        self.categoryRawValue = category.rawValue
        self.latitude = latitude; self.longitude = longitude
        self.address = address; self.province = ""; self.city = ""; self.district = ""; self.country = ""
        self.createdAt = createdAt; self.updatedAt = createdAt; self.photos = []
    }
}

@Model
final class TravelPhoto {
    @Attribute(.unique) var id: UUID
    var fileName: String
    var createdAt: Date
    var caption: String
    var checkIn: CheckIn?

    init(fileName: String, createdAt: Date = .now, caption: String = "") {
        self.id = UUID(); self.fileName = fileName; self.createdAt = createdAt; self.caption = caption
    }
}
