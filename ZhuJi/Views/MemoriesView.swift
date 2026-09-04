import SwiftUI

struct MemoriesView: View {
    @State private var section: MemorySection = .timeline
    var body: some View {
        VStack(spacing: 0) {
            Picker("回忆视图", selection: $section) {
                ForEach(MemorySection.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented).padding(.horizontal).padding(.vertical, 10)
            Group {
                switch section {
                case .timeline: TimelineView()
                case .photos: PhotoGalleryView()
                case .calendar: TravelCalendarView()
                }
            }
        }
    }
}

private enum MemorySection: String, CaseIterable, Identifiable {
    case timeline, photos, calendar
    var id: String { rawValue }
    var title: String { switch self { case .timeline: "时间轴"; case .photos: "照片"; case .calendar: "日历" } }
}
