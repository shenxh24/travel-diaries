import SwiftUI
@preconcurrency import MapKit

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [MKMapItem] = []
    @State private var searching = false
    @State private var errorMessage: String?
    let onSelect: (MKMapItem) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if searching {
                    ProgressView("正在搜索…")
                } else if results.isEmpty {
                    ContentUnavailableView("搜索地点", systemImage: "magnifyingglass", description: Text("输入地点名称、商店、景点或完整地址。"))
                } else {
                    List(results, id: \.self) { item in
                        Button { onSelect(item); dismiss() } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.name ?? "未命名地点").font(.headline).foregroundStyle(.primary)
                                Text(formattedAddress(item.placemark)).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                            }.padding(.vertical, 3)
                        }
                    }
                }
            }
            .navigationTitle("手动选择位置")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "例如：上海外滩")
            .onSubmit(of: .search) { Task { await search() } }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } } }
            .alert("搜索失败", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("好") { errorMessage = nil }
            } message: { Text(errorMessage ?? "请稍后重试。") }
        }
    }

    @MainActor
    private func search() async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        searching = true
        let request = MKLocalSearch.Request(); request.naturalLanguageQuery = text
        do { results = try await MKLocalSearch(request: request).start().mapItems }
        catch { errorMessage = "无法搜索该地点，请检查网络或尝试更完整的名称。" }
        searching = false
    }

    private func formattedAddress(_ mark: MKPlacemark) -> String {
        [mark.country, mark.administrativeArea, mark.locality, mark.subLocality, mark.thoroughfare, mark.subThoroughfare]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
    }
}
