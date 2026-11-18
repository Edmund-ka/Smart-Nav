import SwiftUI

/// Reuses the same local profile photo (or silhouette) on Home and Profile.
struct ProfilePhotoView: View {
    @EnvironmentObject private var profile: ProfilePhotoStore
    var size: CGFloat = 48
    var body: some View {
        Group {
            if let image = profile.image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill").resizable()
                    .foregroundStyle(AppColors.ink, AppColors.accent.opacity(0.3))
            }
        }.frame(width: size, height: size).clipShape(Circle()).accessibilityHidden(true)
    }
}
