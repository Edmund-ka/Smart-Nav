import SwiftUI

/// Load a bundled image only when its name or description changes, not on every playback tick.
struct CampusPhotoView: View, Equatable {
    let name: String
    let description: String
    var body: some View {
        Group {
            if let url = Bundle.main.url(forResource: name, withExtension: "png"),
                let image = UIImage(contentsOfFile: url.path)
            {
                Image(uiImage: image).resizable().scaledToFit()
            } else {
                ContentUnavailableView("Image unavailable", systemImage: "photo")
            }
        }.accessibilityLabel(description)
    }
}
