import SwiftUI
@preconcurrency import MapKit

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [MKMapItem] = []
    @State private var searching = false
    @State private var errorMessage: String?
    @State private var region: SearchRegion = .global
    @State private var showCoordinateEntry = false
    @State private var usedGlobalFallback = false
    @AppStorage("globalSearchFallbackEnabled") private var fallbackEnabled = true
    private let globalSearch = GlobalPlaceSearchService()
    let onSelect: (MKMapItem) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if searching {
                    ProgressView("正在搜索…")
                } else if results.isEmpty {
                    ContentUnavailableView("搜索全球地点", systemImage: "magnifyingglass", description: Text("选择国家或地区，再输入地点、景点或完整地址。"))
                } else {
                    List {
                        if usedGlobalFallback {
                            Label("海外结果由 OpenStreetMap 提供", systemImage: "globe")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        ForEach(results, id: \.self) { item in
                            Button { onSelect(item); dismiss() } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(item.name ?? "未命名地点").font(.headline).foregroundStyle(.primary)
                                    Text(formattedAddress(item.placemark)).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                                }.padding(.vertical, 3)
                            }
                        }
                    }
                }
            }
            .navigationTitle("手动选择位置")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "例如：东京塔")
            .onSubmit(of: .search) { Task { await search() } }
            .safeAreaInset(edge: .top) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SearchRegion.allCases) { item in
                            Button(LocalizedStringKey(item.title)) { region = item }
                                .buttonStyle(.borderedProminent).tint(region == item ? .teal : .gray.opacity(0.25))
                                .foregroundStyle(region == item ? .white : .primary)
                        }
                    }.padding(.horizontal).padding(.vertical, 8)
                }.background(.bar)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .primaryAction) { Button("输入坐标") { showCoordinateEntry = true } }
            }
            .sheet(isPresented: $showCoordinateEntry) {
                CoordinateEntryView { item in onSelect(item); dismiss() }
            }
            .alert("搜索失败", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("好") { errorMessage = nil }
            } message: { Text(LocalizedStringKey(errorMessage ?? "请稍后重试。")) }
        }
    }

    @MainActor
    private func search() async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        searching = true
        usedGlobalFallback = false
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = region.querySuffix.map { "\(text), \($0)" } ?? text
        if let mapRegion = region.mapRegion { request.region = mapRegion }
        do {
            let apple = try await MKLocalSearch(request: request).start().mapItems
            results = region == .global ? apple : apple.filter { region.contains($0.placemark.coordinate) }
        } catch { results = [] }
        if results.isEmpty, region != .china, fallbackEnabled {
            do {
                results = try await globalSearch.search(region.querySuffix.map { "\(text), \($0)" } ?? text).map(makeMapItem)
                usedGlobalFallback = !results.isEmpty
            } catch { errorMessage = "全球地点服务暂时不可用，请稍后重试。" }
        }
        if results.isEmpty, errorMessage == nil { errorMessage = "没有找到该地点，请尝试当地语言、英文或更完整的名称。" }
        searching = false
    }

    private func formattedAddress(_ mark: MKPlacemark) -> String {
        [mark.country, mark.administrativeArea, mark.locality, mark.subLocality, mark.thoroughfare, mark.subThoroughfare]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
    }

    private func makeMapItem(_ result: GlobalPlaceResult) -> MKMapItem {
        let coordinate = CLLocationCoordinate2D(latitude: result.latitude, longitude: result.longitude)
        let address: [String: Any] = ["Country": result.country, "State": result.state, "City": result.city, "SubLocality": result.district, "Street": result.displayName]
        let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: address))
        item.name = result.name
        return item
    }
}

private enum SearchRegion: String, CaseIterable, Identifiable {
    case global, hongKong, singapore, japan, korea, china
    var id: String { rawValue }
    var title: String {
        switch self { case .global: "全球"; case .hongKong: "香港"; case .singapore: "新加坡"; case .japan: "日本"; case .korea: "韩国"; case .china: "中国大陆" }
    }
    var querySuffix: String? { self == .global ? nil : title }
    var mapRegion: MKCoordinateRegion? {
        let value: (Double, Double, Double, Double)? = switch self {
        case .global: nil
        case .hongKong: (22.3193, 114.1694, 1.5, 1.5)
        case .singapore: (1.3521, 103.8198, 1.2, 1.2)
        case .japan: (36.2048, 138.2529, 18, 18)
        case .korea: (36.5, 127.8, 8, 8)
        case .china: (35.8, 104.2, 35, 55)
        }
        guard let value else { return nil }
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: value.0, longitude: value.1), span: MKCoordinateSpan(latitudeDelta: value.2, longitudeDelta: value.3))
    }
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        guard let region = mapRegion else { return true }
        return abs(coordinate.latitude - region.center.latitude) <= region.span.latitudeDelta / 2 && abs(coordinate.longitude - region.center.longitude) <= region.span.longitudeDelta / 2
    }
}

private struct CoordinateEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var name = "手动位置"
    let onSelect: (MKMapItem) -> Void

    private var coordinate: CLLocationCoordinate2D? {
        guard let lat = Double(latitude), let lon = Double(longitude), (-90...90).contains(lat), (-180...180).contains(lon) else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("地点") { TextField("地点名称", text: $name) }
                Section("GPS 坐标") {
                    TextField("纬度，例如 35.6586", text: $latitude).keyboardType(.numbersAndPunctuation)
                    TextField("经度，例如 139.7454", text: $longitude).keyboardType(.numbersAndPunctuation)
                }
                Section { Text("可从 Apple 地图、照片信息或其他地图复制纬度和经度。") }.foregroundStyle(.secondary)
            }
            .navigationTitle("输入坐标").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        guard let coordinate else { return }
                        let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate)); item.name = name
                        onSelect(item); dismiss()
                    }.disabled(coordinate == nil)
                }
            }
        }
    }
}
