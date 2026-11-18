import SwiftUI

/// A decorative backing. The controls above it retain their native hit targets and labels.
struct GlassBackground<S: InsettableShape>: View {
    var shape: S
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Group {
            if reduceTransparency || contrast == .increased {
                shape.fill(AppColors.mist)
            } else {
                shape.fill(.clear)
                    .glassEffect(.regular.tint(AppColors.mist.opacity(0.75)), in: shape)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension View {
    /// One shared background keeps all grouped lists consistent with the sketch palette.
    func glassListCanvas() -> some View {
        scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [
                        AppColors.mist,
                        Color.white,
                        AppColors.accent.opacity(0.12),
                    ], startPoint: .topLeading, endPoint: .bottomTrailing
                ).ignoresSafeArea())
    }
}
