import SwiftUI

struct RootView: View {
    @AppStorage("hasAcceptedPrivacy") private var accepted = false
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if accepted {
                TabView(selection: $selectedTab) {
                    MapHomeView().tabItem { Label("足迹", systemImage: "map.fill") }.tag(0)
                    TimelineView().tabItem { Label("时光轴", systemImage: "clock.fill") }.tag(1)
                    StatisticsView().tabItem { Label("统计", systemImage: "chart.bar.fill") }.tag(2)
                    SettingsView().tabItem { Label("设置", systemImage: "gearshape.fill") }.tag(3)
                }
                .tint(.teal)
            } else {
                PrivacyWelcomeView { accepted = true }
            }
        }
    }
}

private struct PrivacyWelcomeView: View {
    let accept: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "map.circle.fill").font(.system(size: 86)).foregroundStyle(.teal)
            VStack(spacing: 10) {
                Text("欢迎来到驻迹").font(.largeTitle.bold())
                Text("把走过的地方，留在自己的地图上。").foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 14) {
                Label("位置用于创建足迹和展示地图", systemImage: "location.fill")
                Label("照片与日记仅保存在您的设备上", systemImage: "lock.fill")
                Label("地图服务由百度地图提供", systemImage: "map")
            }.padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
            Spacer()
            Button("同意并开始") { accept() }
                .buttonStyle(.borderedProminent).tint(.teal).controlSize(.large)
            Text("继续即表示您同意驻迹使用必要的地图与定位服务。")
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }.padding(28)
    }
}
