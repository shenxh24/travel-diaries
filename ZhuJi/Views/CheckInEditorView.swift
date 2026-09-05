import SwiftUI
import SwiftData
import PhotosUI
import MapKit

struct CheckInEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var checkIn: CheckIn
    let isNew: Bool
    @State private var category: PlaceCategory = .sightseeing
    @State private var photoSelections: [PhotosPickerItem] = []
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var showDeleteConfirmation = false
    @State private var showCamera = false
    @State private var editableCoordinate: CLLocationCoordinate2D
    private let geocoder = GeocodingService()
    private let weather = WeatherService()

    init(checkIn: CheckIn, isNew: Bool) {
        self.checkIn = checkIn
        self.isNew = isNew
        _editableCoordinate = State(initialValue: checkIn.coordinate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DraggableLocationMap(coordinate: $editableCoordinate)
                        .frame(height: 210).clipShape(RoundedRectangle(cornerRadius: 14))
                    Text("按住图钉并拖动，可修正足迹位置。")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("记录") {
                    TextField("地点名称", text: $checkIn.title)
                    Picker("分类", selection: $category) {
                        ForEach(PlaceCategory.allCases) { Label(LocalizedStringKey($0.rawValue), systemImage: $0.symbol).tag($0) }
                    }
                    DatePicker("日期与时间", selection: $checkIn.createdAt)
                    TextField("写下当时的故事…", text: $checkIn.diary, axis: .vertical).lineLimit(4...12)
                }
                Section("位置") {
                    Text(checkIn.address)
                    LabeledContent("坐标", value: String(format: "%.6f, %.6f", checkIn.latitude, checkIn.longitude))
                }
                Section("照片") {
                    if !checkIn.photos.isEmpty { photoGrid }
                    PhotosPicker(selection: $photoSelections, maxSelectionCount: 20, matching: .images) {
                        Label("从照片图库添加", systemImage: "photo.on.rectangle.angled")
                    }
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button { showCamera = true } label: { Label("拍摄照片", systemImage: "camera") }
                    }
                }
                if let temperature = checkIn.temperature, let condition = checkIn.weatherCondition {
                    Section("天气") { Label("\(condition)  \(temperature, specifier: "%.1f")°C", systemImage: "cloud.sun") }
                }
                if !isNew {
                    Section { Button("删除这条足迹", role: .destructive) { showDeleteConfirmation = true } }
                }
            }
            .navigationTitle(LocalizedStringKey(isNew ? "添加足迹" : "足迹详情"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { if isNew { context.delete(checkIn) }; dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存") { save() }.bold() }
            }
            .onAppear {
                category = checkIn.category
                mapPosition = .region(MKCoordinateRegion(center: checkIn.coordinate, latitudinalMeters: 500, longitudinalMeters: 500))
            }
            .task { await updateAddressIfNeeded() }
            .onChange(of: photoSelections) { _, values in Task { await importPhotos(values) } }
            .fullScreenCover(isPresented: $showCamera) { CameraPicker { data in if let data { importCameraPhoto(data) } } }
            .confirmationDialog("确定删除这条足迹吗？", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("删除", role: .destructive) { context.delete(checkIn); dismiss() }
            }
        }
    }

    private var photoGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("点击照片设为时间轴封面").font(.caption).foregroundStyle(.secondary)
            ScrollView(.horizontal) {
                LazyHStack {
                ForEach(checkIn.photos) { photo in
                    if let image = PhotoStore.image(named: photo.fileName) {
                        Button { checkIn.featuredPhotoID = photo.id } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image).resizable().scaledToFill()
                                    .frame(width: 110, height: 90).clipShape(RoundedRectangle(cornerRadius: 10))
                                if checkIn.featuredPhoto?.id == photo.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2).foregroundStyle(.white, .teal)
                                        .padding(5)
                                }
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(checkIn.featuredPhoto?.id == photo.id ? Color.teal : .clear, lineWidth: 3)
                            }
                        }.buttonStyle(.plain)
                    }
                }
                }
            }
            .frame(height: 96)
        }
    }

    private func save() {
        checkIn.category = category
        checkIn.latitude = editableCoordinate.latitude; checkIn.longitude = editableCoordinate.longitude
        checkIn.updatedAt = .now; try? context.save(); dismiss()
    }

    private func updateAddressIfNeeded() async {
        guard (checkIn.address == "正在获取地址…" || checkIn.country.isEmpty),
              let result = await geocoder.reverse(checkIn.coordinate) else { return }
        checkIn.address = result.formatted; checkIn.province = result.province; checkIn.city = result.city; checkIn.district = result.district; checkIn.country = result.country
        if let stamp = await weather.current(at: checkIn.coordinate) {
            checkIn.temperature = stamp.temperature; checkIn.weatherCondition = stamp.condition
        }
    }

    private func importPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self), let name = try? PhotoStore.save(data) else { continue }
            let photo = TravelPhoto(fileName: name); photo.checkIn = checkIn; checkIn.photos.append(photo)
            if checkIn.featuredPhotoID == nil { checkIn.featuredPhotoID = photo.id }
        }
        photoSelections = []
    }

    private func importCameraPhoto(_ data: Data) {
        guard let name = try? PhotoStore.save(data) else { return }
        let photo = TravelPhoto(fileName: name); photo.checkIn = checkIn; checkIn.photos.append(photo)
        if checkIn.featuredPhotoID == nil { checkIn.featuredPhotoID = photo.id }
    }
}
