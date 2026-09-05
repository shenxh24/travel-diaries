import SwiftUI
import SwiftData
import CoreLocation

struct TravelCalendarView: View {
    @Query(sort: \CheckIn.createdAt) private var checkIns: [CheckIn]
    @State private var month = Date.now
    @State private var selectedDay: DaySelection?
    @Environment(\.locale) private var locale
    private var calendar: Calendar {
        var value = Calendar.current
        value.locale = locale
        return value
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    monthHeader
                    weekdayHeader
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                        ForEach(daysForMonth, id: \.self) { day in
                            if let day {
                                dayCell(day)
                            } else {
                                Color.clear.frame(height: 62)
                            }
                        }
                    }
                }.padding()
            }
            .navigationTitle("旅行日历")
            .sheet(item: $selectedDay) { DailySummaryView(date: $0.date, checkIns: $0.items) }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { changeMonth(-1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(month.formatted(.dateTime.year().month(.wide))).font(.title2.bold())
            Spacer()
            Button { changeMonth(1) } label: { Image(systemName: "chevron.right") }
        }.buttonStyle(.borderless).foregroundStyle(.teal)
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(calendar.veryShortStandaloneWeekdaySymbols, id: \.self) { Text($0).frame(maxWidth: .infinity).font(.caption.bold()).foregroundStyle(.secondary) }
        }
    }

    private var daysForMonth: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let weekday = calendar.component(.weekday, from: interval.start)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        return Array(repeating: nil, count: leading) + range.compactMap { day in calendar.date(byAdding: .day, value: day - 1, to: interval.start) }.map(Optional.some)
    }

    private func dayCell(_ day: Date) -> some View {
        let items = checkIns.filter { calendar.isDate($0.createdAt, inSameDayAs: day) }
        return Button { if !items.isEmpty { selectedDay = DaySelection(date: day, items: items) } } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: day))").font(.subheadline.weight(items.isEmpty ? .regular : .bold))
                if let photo = items.first?.featuredPhoto, let image = PhotoStore.image(named: photo.fileName) {
                    Image(uiImage: image).resizable().scaledToFill().frame(width: 38, height: 30).clipShape(RoundedRectangle(cornerRadius: 5))
                } else if !items.isEmpty {
                    Circle().fill(.teal).frame(width: 7, height: 7)
                } else { Color.clear.frame(height: 7) }
            }.frame(maxWidth: .infinity).frame(height: 62)
                .background(items.isEmpty ? Color.clear : Color.teal.opacity(0.09), in: RoundedRectangle(cornerRadius: 10))
        }.buttonStyle(.plain)
    }

    private func changeMonth(_ value: Int) { if let date = calendar.date(byAdding: .month, value: value, to: month) { month = date } }
}

private struct DaySelection: Identifiable {
    let date: Date
    let items: [CheckIn]
    var id: Date { date }
}

private struct DailySummaryView: View {
    let date: Date
    let checkIns: [CheckIn]
    @Environment(\.dismiss) private var dismiss
    private var distance: Double {
        let sorted = checkIns.sorted { $0.createdAt < $1.createdAt }
        return zip(sorted, sorted.dropFirst()).reduce(0) { value, pair in
            value + CLLocation(latitude: pair.0.latitude, longitude: pair.0.longitude).distance(from: CLLocation(latitude: pair.1.latitude, longitude: pair.1.longitude))
        }
    }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack { summary("足迹", "\(checkIns.count)"); summary("照片", "\(checkIns.reduce(0) { $0 + $1.photos.count })"); summary("距离", distance >= 1000 ? String(format: "%.1f公里", distance / 1000) : String(format: "%.0f米", distance)) }
                }
                ForEach(checkIns.sorted { $0.createdAt < $1.createdAt }) { item in
                    Section(item.createdAt.formatted(date: .omitted, time: .shortened)) {
                        TimelineSummaryRow(item: item)
                        if let weather = item.weatherCondition, let temperature = item.temperature { Label("\(weather)  \(temperature, specifier: "%.1f")°C", systemImage: "cloud.sun") }
                        if !item.diary.isEmpty { Text(item.diary) }
                    }
                }
            }.navigationTitle(date.formatted(date: .long, time: .omitted))
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
        }
    }
    private func summary(_ title: String, _ value: String) -> some View {
        VStack { Text(value).font(.headline); Text(LocalizedStringKey(title)).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity)
    }
}

private struct TimelineSummaryRow: View {
    let item: CheckIn
    var body: some View {
        HStack(spacing: 12) {
            if let photo = item.featuredPhoto, let image = PhotoStore.image(named: photo.fileName) {
                Image(uiImage: image).resizable().scaledToFill().frame(width: 58, height: 58).clipShape(RoundedRectangle(cornerRadius: 9))
            } else { Image(systemName: item.category.symbol).frame(width: 58, height: 58).background(.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 9)) }
            VStack(alignment: .leading) { Text(item.title).font(.headline); Text(item.address).font(.caption).foregroundStyle(.secondary).lineLimit(2) }
        }
    }
}
