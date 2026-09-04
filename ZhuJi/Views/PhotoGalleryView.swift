import SwiftUI
import SwiftData

private struct PhotoMoment: Identifiable {
    let photo: TravelPhoto
    let checkIn: CheckIn
    var id: UUID { photo.id }
}

struct PhotoGalleryView: View {
    @Query(sort: \CheckIn.createdAt, order: .reverse) private var checkIns: [CheckIn]
    @State private var selectedID: UUID?
    @State private var showSlideshow = false

    private var moments: [PhotoMoment] {
        checkIns.flatMap { checkIn in checkIn.photos.sorted { $0.createdAt > $1.createdAt }.map { PhotoMoment(photo: $0, checkIn: checkIn) } }
    }

    var body: some View {
        NavigationStack {
            Group {
                if moments.isEmpty {
                    ContentUnavailableView("还没有照片", systemImage: "photo.on.rectangle.angled", description: Text("为足迹添加照片后，它们会出现在这里。"))
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3), spacing: 3) {
                            ForEach(moments) { moment in
                                Button { selectedID = moment.id; showSlideshow = true } label: {
                                    if let image = PhotoStore.image(named: moment.photo.fileName) {
                                        Image(uiImage: image).resizable().scaledToFill()
                                            .frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fill).clipped()
                                    }
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle("全部照片")
            .fullScreenCover(isPresented: $showSlideshow) {
                PhotoSlideshowView(moments: moments, selection: $selectedID)
            }
        }
    }
}

private struct PhotoSlideshowView: View {
    let moments: [PhotoMoment]
    @Binding var selection: UUID?
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            TabView(selection: $selection) {
                ForEach(moments) { moment in
                    VStack(spacing: 0) {
                        Spacer()
                        if let image = PhotoStore.image(named: moment.photo.fileName) {
                            Image(uiImage: image).resizable().scaledToFit()
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 5) {
                            Text(moment.checkIn.title).font(.headline)
                            Text(moment.checkIn.createdAt.formatted(date: .long, time: .shortened)).font(.subheadline).foregroundStyle(.secondary)
                            if !moment.checkIn.address.isEmpty { Text(moment.checkIn.address).font(.caption).foregroundStyle(.secondary).lineLimit(2) }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.ultraThinMaterial)
                    }.tag(Optional(moment.id))
                }
            }.tabViewStyle(.page(indexDisplayMode: .always))
            Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.largeTitle).symbolRenderingMode(.palette).foregroundStyle(.white, .black.opacity(0.5)) }
                .padding()
        }.preferredColorScheme(.dark)
    }
}
