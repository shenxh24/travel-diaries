import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query(sort: \CheckIn.createdAt) private var checkIns: [CheckIn]
    @AppStorage("hasAcceptedPrivacy") private var acceptedPrivacy = true
    @State private var exportURL: URL?
    @State private var showExporter = false
    @State private var isExporting = false
    @State private var exportError: String?
    @AppStorage("globalSearchFallbackEnabled") private var globalSearchFallbackEnabled = true
    @AppStorage("appLanguage") private var appLanguage = "zh-Hans"

    var body: some View {
        NavigationStack {
            Form {
                Section("语言") {
                    Picker("界面语言", selection: $appLanguage) {
                        Text("简体中文").tag("zh-Hans")
                        Text("English").tag("en")
                    }
                    .pickerStyle(.segmented)
                    Text("语言更改会立即应用，您写下的地点和日记不会被翻译或修改。")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("数据") {
                    LabeledContent("足迹数量", value: "\(checkIns.count)")
                    LabeledContent("照片数量", value: "\(checkIns.reduce(0) { $0 + $1.photos.count })")
                    Button { export() } label: {
                        Label(LocalizedStringKey(isExporting ? "正在整理照片…" : "导出互动旅行网页"), systemImage: isExporting ? "hourglass" : "square.and.arrow.up")
                    }.disabled(isExporting || checkIns.isEmpty)
                    Text("包含全部足迹、日记与照片，可离线打开并浏览幻灯片。")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("离线地图") {
                    NavigationLink { OfflineMapView() } label: { Label("管理城市离线地图", systemImage: "arrow.down.circle") }
                }
                Section("隐私") {
                    Label("位置、日记和照片默认仅保存在本机", systemImage: "lock.shield")
                    Button("重新查看隐私说明") { acceptedPrivacy = false }
                }
                Section("地点搜索") {
                    Toggle("海外地点搜索", isOn: $globalSearchFallbackEnabled)
                    Text("Apple 地图找不到海外地点时使用 OpenStreetMap。中国大陆搜索始终使用 Apple 地图。")
                        .font(.caption).foregroundStyle(.secondary)
                    Link("© OpenStreetMap 贡献者", destination: URL(string: "https://www.openstreetmap.org/copyright")!)
                }
                Section("关于") {
                    LabeledContent("应用", value: "驻迹")
                    LabeledContent("版本", value: "1.0")
                    Text("把走过的地方，留在自己的地图上。")
                }
            }.navigationTitle("设置")
            .overlay {
                if isExporting {
                    ZStack {
                        Color.black.opacity(0.18).ignoresSafeArea()
                        VStack(spacing: 14) {
                            ProgressView().controlSize(.large).tint(.teal)
                            Text("正在制作旅行网页").font(.headline)
                            Text("照片较多时可能需要一点时间，请稍候。")
                                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        }.padding(26).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
            .sheet(isPresented: $showExporter) {
                if let exportURL { ExportReadyView(url: exportURL) }
            }
            .alert("导出失败", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
                Button("好") { exportError = nil }
            } message: { Text(LocalizedStringKey(exportError ?? "请稍后重试。")) }
        }
    }
    private func export() {
        isExporting = true
        Task {
            do { exportURL = try await ExportService.createInteractiveDiary(checkIns); isExporting = false; showExporter = true }
            catch { isExporting = false; exportError = "无法创建网页：\(error.localizedDescription)" }
        }
    }
}

private struct OfflineMapView: View {
    var body: some View {
        List {
            Section {
                Label("Apple 离线地图由系统“地图”App统一管理，驻迹会自动使用系统已有的地图数据。", systemImage: "iphone.and.arrow.forward")
            }
            Section("下载方法") {
                Text("1. 打开 Apple“地图”App")
                Text("2. 点击右上角头像")
                Text("3. 选择“离线地图”")
                Text("4. 点击“下载新地图”并选择城市或区域")
            }
        }
        .navigationTitle("离线地图").navigationBarTitleDisplayMode(.inline)
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

private struct ExportReadyView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var showShare = false
    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "checkmark.circle.fill").font(.system(size: 72)).foregroundStyle(.teal)
                Text("旅行网页已完成").font(.title2.bold())
                Text("请保存到“文件”，然后点击 HTML 文件即可浏览。也可以通过隔空投送发送到 Mac。")
                    .foregroundStyle(.secondary).multilineTextAlignment(.center)
                Button("保存或分享网页") { showShare = true }.buttonStyle(.borderedProminent).tint(.teal).controlSize(.large)
                Spacer()
            }.padding(30).navigationTitle("导出完成")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } } }
                .sheet(isPresented: $showShare) { ShareSheet(items: [url]) }
        }
    }
}
