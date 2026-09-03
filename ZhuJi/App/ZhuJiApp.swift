import SwiftUI
import SwiftData

@main
struct ZhuJiApp: App {
    private let container: ModelContainer = {
        let schema = Schema([CheckIn.self, TravelPhoto.self])
        let configuration = ModelConfiguration("驻迹", schema: schema)
        do { return try ModelContainer(for: schema, configurations: [configuration]) }
        catch { fatalError("无法创建本地数据库：\(error.localizedDescription)") }
    }()

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

