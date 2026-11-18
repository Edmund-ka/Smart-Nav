import Combine
import SwiftUI

/// Persists one local profile photo. There is no account or remote upload.
final class ProfilePhotoStore: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published var photoError: String?
    private let url = URL.applicationSupportDirectory.appending(path: "profile.jpg")

    init() {
        if let data = try? Data(contentsOf: url) { image = UIImage(data: data) }
    }

    /// Crop to a small square before saving, so full camera images are not repeatedly decoded.
    func setPhoto(_ data: Data?) {
        do {
            if let data {
                guard let original = UIImage(data: data) else { throw CocoaError(.fileReadCorruptFile) }
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: 512, height: 512))
                let resized = renderer.image { _ in
                    let scale = max(512 / original.size.width, 512 / original.size.height)
                    let width = original.size.width * scale
                    let height = original.size.height * scale
                    original.draw(in: CGRect(x: (512 - width) / 2, y: (512 - height) / 2, width: width, height: height))
                }
                guard let jpeg = resized.jpegData(compressionQuality: 0.85) else { throw CocoaError(.fileWriteUnknown) }
                try FileManager.default.createDirectory(
                    at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try jpeg.write(to: url, options: .atomic)
                image = resized
            } else {
                if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
                image = nil
            }
            photoError = nil
        } catch { photoError = "Your photo could not be saved. Please try again." }
    }
}
