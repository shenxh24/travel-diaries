import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query(sort: \CheckIn.createdAt) private var checkIns: [CheckIn]
    @AppStorage("hasAcceptedPrivacy") private var acceptedPrivacy = true
    @State private var exportURL: URL?
    @State private var showExporter = false

    var body: some View {
        NavigationStack {
            Form {
                Section("数据") {
                    LabeledContent("足迹数量", value: "\(checkIns.count)")
                    LabeledContent("照片数量", value: "\(checkIns.reduce(0) { $0 + $1.photos.count })")
                    Button { export() } label: { Label("导出 JSON 备份", systemImage: "square.and.arrow.up") }
                }
                Section("离线地图") {
                    NavigationLink { OfflineMapView() } label: { Label("管理城市离线地图", systemImage: "arrow.down.circle") }
                }
                Section("隐私") {
                    Label("位置、日记和照片默认仅保存在本机", systemImage: "lock.shield")
                    Button("重新查看隐私说明") { acceptedPrivacy = false }
                }
                Section("关于") {
                    LabeledContent("应用", value: "驻迹")
                    LabeledContent("版本", value: "1.0")
                    Text("把走过的地方，留在自己的地图上。")
                }
            }.navigationTitle("设置")
            .sheet(isPresented: $showExporter) {
                if let exportURL { ShareSheet(items: [exportURL]) }
            }
        }
    }
    private func export() { exportURL = try? ExportService.createJSON(checkIns); showExporter = exportURL != nil }
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
