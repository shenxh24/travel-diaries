import Foundation
import UIKit

enum PhotoStore {
    private static var directory: URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return root.appending(path: "TravelPhotos", directoryHint: .isDirectory)
    }

    static func save(_ data: Data) throws -> String {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        guard let image = UIImage(data: data), let compressed = resized(image).jpegData(compressionQuality: 0.7) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        let name = UUID().uuidString + ".jpg"
        try compressed.write(to: directory.appending(path: name), options: .atomic)
        return name
    }

    static func image(named name: String) -> UIImage? {
        UIImage(contentsOfFile: directory.appending(path: name).path)
    }

    static func url(named name: String) -> URL { directory.appending(path: name) }

    private static func resized(_ image: UIImage) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > 1024 else { return image }
        let scale = 1024 / longest
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        return UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    }
}

