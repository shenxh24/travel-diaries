import SwiftUI
import SwiftData

struct TimelineView: View {
    @Query(sort: \CheckIn.createdAt, order: .reverse) private var items: [CheckIn]
    @State private var selected: CheckIn?
    @State private var searchText = ""

    private var filtered: [CheckIn] {
        guard !searchText.isEmpty else { return items }
        return items.filter { $0.title.localizedCaseInsensitiveContains(searchText) || $0.address.localizedCaseInsensitiveContains(searchText) || $0.diary.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    ContentUnavailableView(
                        LocalizedStringKey(searchText.isEmpty ? "还没有足迹" : "没有找到足迹"),
                        systemImage: "map",
                        description: Text(LocalizedStringKey(searchText.isEmpty ? "在地图中点击加号，留下第一条旅行记录。" : "试试搜索其他地点或文字。"))
                    )
                } else {
                    List(filtered) { item in
                        Button { selected = item } label: { TimelineRow(item: item) }.buttonStyle(.plain)
                    }.listStyle(.plain)
                }
            }
            .navigationTitle("时光轴")
            .searchable(text: $searchText, prompt: "搜索地点和日记")
            .sheet(item: $selected) { CheckInEditorView(checkIn: $0, isNew: false) }
        }
    }
}

private struct TimelineRow: View {
    let item: CheckIn
    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let photo = item.featuredPhoto, let image = PhotoStore.image(named: photo.fileName) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    ZStack { Color.teal.opacity(0.12); Image(systemName: item.category.symbol).foregroundStyle(.teal) }
                }
            }.frame(width: 74, height: 74).clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 5) {
                Text(item.title).font(.headline).lineLimit(1)
                Text(item.address).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.tertiary)
            }
        }.padding(.vertical, 4)
    }
}
