import Foundation

struct ExportCheckIn: Codable {
    let id: UUID, title: String, diary: String, category: String, address: String
    let latitude: Double, longitude: Double, createdAt: Date
    let temperature: Double?, weatherCondition: String?, photos: [String]
}

private struct ExportDiaryEntry: Sendable {
    let title: String, diary: String, category: String, address: String
    let latitude: Double, longitude: Double, createdAt: Date
    let temperature: Double?, weatherCondition: String?, photoURLs: [URL]
}

enum ExportService {
    static func createJSON(_ items: [CheckIn]) throws -> URL {
        let payload = items.map { ExportCheckIn(id: $0.id, title: $0.title, diary: $0.diary, category: $0.categoryRawValue, address: $0.address, latitude: $0.latitude, longitude: $0.longitude, createdAt: $0.createdAt, temperature: $0.temperature, weatherCondition: $0.weatherCondition, photos: $0.photos.map(\.fileName)) }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
        let url = FileManager.default.temporaryDirectory.appending(path: "驻迹备份-\(Date.now.formatted(.iso8601.year().month().day())).json")
        try encoder.encode(payload).write(to: url, options: .atomic)
        return url
    }

    @MainActor
    static func createInteractiveDiary(_ items: [CheckIn]) async throws -> URL {
        let snapshots = items.map { item in
            ExportDiaryEntry(title: item.title, diary: item.diary, category: item.categoryRawValue, address: item.address,
                             latitude: item.latitude, longitude: item.longitude, createdAt: item.createdAt,
                             temperature: item.temperature, weatherCondition: item.weatherCondition,
                             photoURLs: item.photos.map { PhotoStore.url(named: $0.fileName) })
        }
        return try await Task.detached(priority: .userInitiated) { try buildInteractiveDiary(snapshots) }.value
    }

    private static func buildInteractiveDiary(_ items: [ExportDiaryEntry]) throws -> URL {
        let sorted = items.sorted { $0.createdAt < $1.createdAt }
        let cards = sorted.map(cardHTML).joined(separator: "\n")
        let photoCount = sorted.reduce(0) { $0 + $1.photoURLs.count }
        let html = """
        <!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
        <title>驻迹 · 我的旅行回忆</title><style>
        :root{--ink:#163c38;--teal:#0e7d74;--paper:#f5efe3;--card:#fffdf8;--muted:#6d7976}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:16px/1.55 -apple-system,BlinkMacSystemFont,"PingFang SC",sans-serif}header{padding:64px 22px 34px;max-width:960px;margin:auto}h1{font-size:clamp(40px,8vw,76px);line-height:1;margin:0 0 14px;letter-spacing:-.04em}.lead{color:var(--muted);font-size:18px}.stats{display:flex;gap:12px;margin-top:26px}.stat{background:rgba(255,255,255,.56);padding:13px 18px;border-radius:16px}.stat b{display:block;font-size:22px}.timeline{max-width:960px;margin:auto;padding:0 18px 80px}.entry{background:var(--card);border-radius:24px;padding:18px;margin:0 0 18px;box-shadow:0 8px 32px rgba(22,60,56,.07)}.meta{color:var(--muted);font-size:14px}.entry h2{margin:5px 0 3px;font-size:25px}.photos{display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:7px;margin-top:16px}.photos img{width:100%;aspect-ratio:1.15;object-fit:cover;border-radius:13px;cursor:zoom-in}.diary{white-space:pre-wrap;margin-top:15px}.map{display:inline-block;color:var(--teal);text-decoration:none;margin-top:9px;font-weight:600}.viewer{position:fixed;inset:0;background:#07100fee;display:none;align-items:center;justify-content:center;z-index:10}.viewer.open{display:flex}.viewer img{max-width:94vw;max-height:82vh;object-fit:contain}.close,.prev,.next{position:fixed;border:0;background:#ffffff22;color:white;border-radius:99px;font-size:25px;width:48px;height:48px}.close{right:18px;top:18px}.prev{left:18px}.next{right:18px}@media(max-width:560px){header{padding-top:46px}.photos{grid-template-columns:repeat(2,1fr)}.entry{border-radius:18px}.stats{flex-wrap:wrap}}
        </style></head><body><header><h1>驻迹</h1><div class="lead">把走过的地方，留在自己的地图上。</div><div class="stats"><div class="stat"><b>\(sorted.count)</b>足迹</div><div class="stat"><b>\(photoCount)</b>照片</div></div></header><main class="timeline">\(cards)</main>
        <div class="viewer" id="viewer"><button class="close" aria-label="关闭">×</button><button class="prev" aria-label="上一张">‹</button><img alt="旅行照片"><button class="next" aria-label="下一张">›</button></div>
        <script>const imgs=[...document.querySelectorAll('.photos img')],v=document.querySelector('#viewer'),big=v.querySelector('img');let n=0;function show(i){n=(i+imgs.length)%imgs.length;big.src=imgs[n].src;v.classList.add('open')}imgs.forEach((x,i)=>x.onclick=()=>show(i));v.querySelector('.close').onclick=()=>v.classList.remove('open');v.querySelector('.prev').onclick=()=>show(n-1);v.querySelector('.next').onclick=()=>show(n+1);document.onkeydown=e=>{if(e.key==='Escape')v.classList.remove('open');if(v.classList.contains('open')&&e.key==='ArrowLeft')show(n-1);if(v.classList.contains('open')&&e.key==='ArrowRight')show(n+1)}</script></body></html>
        """
        let url = FileManager.default.temporaryDirectory.appending(path: "驻迹旅行回忆-\(Date.now.formatted(.iso8601.year().month().day())).html")
        guard let data = html.data(using: .utf8) else { throw CocoaError(.fileWriteInapplicableStringEncoding) }
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func cardHTML(_ item: ExportDiaryEntry) -> String {
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "zh_CN"); formatter.dateStyle = .long; formatter.timeStyle = .short
        let photos = item.photoURLs.map { url -> String in
            guard let data = try? Data(contentsOf: url) else { return "" }
            return "<img loading=\"lazy\" src=\"data:image/jpeg;base64,\(data.base64EncodedString())\" alt=\"\(escape(item.title))\">"
        }.joined()
        let weather = [item.weatherCondition, item.temperature.map { String(format: "%.1f°C", $0) }].compactMap { $0 }.joined(separator: " · ")
        let mapURL = "https://maps.apple.com/?ll=\(item.latitude),\(item.longitude)&q=\(item.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        return """
        <article class="entry"><div class="meta">\(escape(formatter.string(from: item.createdAt))) · \(escape(item.category))\(weather.isEmpty ? "" : " · \(escape(weather))")</div><h2>\(escape(item.title))</h2><div class="meta">\(escape(item.address))</div><a class="map" href="\(mapURL)">在 Apple 地图中查看 ↗</a>\(item.diary.isEmpty ? "" : "<div class=\"diary\">\(escape(item.diary))</div>")<div class="photos">\(photos)</div></article>
        """
    }

    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
    }
}
