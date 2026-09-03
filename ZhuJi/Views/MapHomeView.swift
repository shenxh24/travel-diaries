import SwiftUI
import SwiftData
import MapKit

struct MapHomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CheckIn.createdAt, order: .reverse) private var checkIns: [CheckIn]
    @StateObject private var locationService = LocationService()
    @State private var position: MapCameraPosition = .automatic
    @State private var draftCoordinate: CLLocationCoordinate2D?
    @State private var editing: CheckIn?
    @State private var selected: CheckIn?
    @State private var showAddOptions = false
    @State private var showLocationSearch = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Map(position: $position, selection: $selected) {
                    UserAnnotation()
                    ForEach(checkIns) { item in
                        Annotation(item.title, coordinate: item.coordinate, anchor: .bottom) {
                            MarkerBadge(item: item)
                        }.tag(item)
                    }
                }
                .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .all, showsTraffic: false))
                .mapControls { MapCompass(); MapScaleView(); MapPitchToggle() }
                .onMapCameraChange(frequency: .onEnd) { _ in }

                VStack(spacing: 12) {
                    Button { centerOnUser() } label: { Image(systemName: "location.fill") }
                        .accessibilityLabel("回到当前位置")
                    Button { showAddOptions = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("添加足迹")
                }
                .font(.title3.bold()).buttonStyle(FloatingButtonStyle()).padding(18)
            }
            .navigationTitle("驻迹")
            .navigationBarTitleDisplayMode(.inline)
            .task { locationService.requestPermissionAndStart() }
            .onChange(of: locationService.location) { old, new in
                if old == nil, let coordinate = new?.coordinate {
                    position = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 1200, longitudinalMeters: 1200))
                }
            }
            .sheet(item: $editing) { item in CheckInEditorView(checkIn: item, isNew: true) }
            .sheet(item: $selected) { item in CheckInEditorView(checkIn: item, isNew: false) }
            .sheet(isPresented: $showLocationSearch) {
                LocationSearchView { mapItem in add(mapItem: mapItem) }
            }
            .confirmationDialog("添加足迹", isPresented: $showAddOptions, titleVisibility: .visible) {
                Button("使用当前位置") { addAtCurrentLocation() }
                Button("搜索地点") { showLocationSearch = true }
                Button("取消", role: .cancel) {}
            }
            .alert("无法获取位置", isPresented: Binding(get: { locationService.errorMessage != nil }, set: { if !$0 { locationService.errorMessage = nil } })) {
                Button("好") { locationService.errorMessage = nil }
            } message: { Text(locationService.errorMessage ?? "请在系统设置中允许定位。") }
        }
    }

    private func centerOnUser() {
        guard let coordinate = locationService.location?.coordinate else { locationService.requestCurrentLocation(); return }
        withAnimation { position = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 800, longitudinalMeters: 800)) }
    }

    private func addAtCurrentLocation() {
        guard let coordinate = locationService.location?.coordinate else {
            locationService.errorMessage = "暂时没有定位结果，请稍后重试。"; locationService.requestCurrentLocation(); return
        }
        let item = CheckIn(latitude: coordinate.latitude, longitude: coordinate.longitude)
        context.insert(item); editing = item
    }

    private func add(mapItem: MKMapItem) {
        let coordinate = mapItem.placemark.coordinate
        let address = [mapItem.placemark.country, mapItem.placemark.administrativeArea, mapItem.placemark.locality,
                       mapItem.placemark.subLocality, mapItem.placemark.thoroughfare, mapItem.placemark.subThoroughfare]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
        let item = CheckIn(title: mapItem.name ?? "新的足迹", latitude: coordinate.latitude,
                           longitude: coordinate.longitude, address: address.isEmpty ? "已手动选择位置" : address)
        item.country = mapItem.placemark.country ?? ""
        item.province = mapItem.placemark.administrativeArea ?? ""
        item.city = mapItem.placemark.locality ?? ""
        item.district = mapItem.placemark.subLocality ?? ""
        context.insert(item)
        position = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 900, longitudinalMeters: 900))
        editing = item
    }
}

private struct MarkerBadge: View {
    let item: CheckIn
    var body: some View {
        ZStack {
            Circle().fill(categoryColor).frame(width: 42, height: 42).shadow(radius: 3, y: 2)
            Image(systemName: item.category.symbol).foregroundStyle(.white)
        }
    }
    private var categoryColor: Color {
        switch item.category { case .food: .orange; case .sightseeing: .blue; case .city: .teal; case .shopping: .pink }
    }
}

private struct FloatingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.frame(width: 50, height: 50).background(.regularMaterial, in: Circle())
            .shadow(color: .black.opacity(0.18), radius: 8, y: 3).scaleEffect(configuration.isPressed ? 0.92 : 1)
    }
}
