import SwiftUI
import SwiftData
import CoreLocation

struct StatisticsView: View {
    @Query(sort: \CheckIn.createdAt) private var checkIns: [CheckIn]

    private var totalDistance: CLLocationDistance {
        zip(checkIns, checkIns.dropFirst()).reduce(0) { result, pair in
            result + CLLocation(latitude: pair.0.latitude, longitude: pair.0.longitude)
                .distance(from: CLLocation(latitude: pair.1.latitude, longitude: pair.1.longitude))
        }
    }

    private var cities: Set<String> { unique(\.city) }
    private var provinces: Set<String> { unique(\.province) }
    private var countries: Set<String> { unique(\.country) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    distanceCard
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        StatCard(value: "\(cities.count)", title: "城市", symbol: "building.2.fill", color: .teal)
                        StatCard(value: "\(provinces.count)", title: "省份/地区", symbol: "map.fill", color: .blue)
                        StatCard(value: "\(countries.count)", title: "国家", symbol: "globe.asia.australia.fill", color: .indigo)
                        StatCard(value: "\(checkIns.count)", title: "足迹", symbol: "mappin.and.ellipse", color: .orange)
                    }
                    if checkIns.count < 2 {
                        ContentUnavailableView("继续留下足迹", systemImage: "figure.walk", description: Text("至少记录两个地点后，驻迹会估算旅程距离。"))
                            .frame(minHeight: 220)
                    } else {
                        Text("距离按足迹的时间顺序，以地点间直线距离估算，并不等同于实际道路里程。")
                            .font(.caption).foregroundStyle(.secondary).padding(.horizontal)
                    }
                }.padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("旅行统计")
        }
    }

    private var distanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("累计旅行距离", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                .font(.headline).foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(distanceValue).font(.system(size: 46, weight: .bold, design: .rounded))
                Text(LocalizedStringKey(distanceUnit)).font(.title3.bold()).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(22)
        .background(.background, in: RoundedRectangle(cornerRadius: 22))
    }

    private var distanceValue: String {
        totalDistance >= 1_000 ? String(format: "%.1f", totalDistance / 1_000) : String(format: "%.0f", totalDistance)
    }
    private var distanceUnit: String { totalDistance >= 1_000 ? "公里" : "米" }

    private func unique(_ keyPath: KeyPath<CheckIn, String>) -> Set<String> {
        Set(checkIns.map { $0[keyPath: keyPath].trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
    }
}

private struct StatCard: View {
    let value: String
    let title: String
    let symbol: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol).font(.title2).foregroundStyle(color)
            Text(value).font(.system(size: 32, weight: .bold, design: .rounded))
            Text(LocalizedStringKey(title)).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
    }
}
