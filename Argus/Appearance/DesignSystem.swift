import SwiftUI

/// Shared spacing and shape tokens. An 8-point grid keeps rhythm consistent between screens.
enum Spacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
}

enum Radius {
    static let control: CGFloat = 14
    static let card: CGFloat = 22
    static let sheet: CGFloat = 28
}

/// iOS Settings-style coloured square with a symbol: rows are recognisable at a glance.
struct IconBadge: View {
    let symbol: String
    var tint: Color = AppColors.ink
    var size: CGFloat = 30
    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.48, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(tint.gradient, in: RoundedRectangle(cornerRadius: size * 0.27, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// A row label with a leading badge, used in Profile and Record lists.
struct BadgeLabel: View {
    let title: String
    let symbol: String
    var tint: Color = AppColors.ink
    var body: some View {
        HStack(spacing: Spacing.m) {
            IconBadge(symbol: symbol, tint: tint)
            Text(title)
        }
    }
}

/// Small rounded label for facts and quick choices.
struct Chip: View {
    let text: String
    var symbol: String?
    var prominent = false
    var body: some View {
        HStack(spacing: 5) {
            if let symbol { Image(systemName: symbol).font(.system(size: 11, weight: .bold)) }
            Text(text).lineLimit(1)
        }
        .font(.poppins(.caption, weight: .semibold))
        .padding(.horizontal, 10).padding(.vertical, 6)
        .foregroundStyle(prominent ? .white : AppColors.ink)
        .background(
            prominent ? AnyShapeStyle(AppColors.ink) : AnyShapeStyle(AppColors.ink.opacity(0.07)), in: Capsule())
    }
}

/// One large figure with a caption, for metrics that should be readable at arm's length.
struct StatTile: View {
    let value: String
    let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.poppins(.title3, weight: .bold)).monospacedDigit()
                .contentTransition(.numericText())
            Text(label).font(.poppins(.caption)).foregroundStyle(AppColors.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.m)
        .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// Map pin shared by Home and Simulate so destinations look the same everywhere.
struct PlacePin: View {
    var icon: String
    var tint: Color = AppColors.accent
    var pulsing = false
    @State private var pulse = false
    var body: some View {
        VStack(spacing: -3) {
            ZStack {
                if pulsing {
                    Circle().stroke(tint, lineWidth: 3).frame(width: 40, height: 40)
                        .scaleEffect(pulse ? 2.1 : 1).opacity(pulse ? 0 : 0.8)
                }
                Circle().fill(tint).frame(width: 40, height: 40)
                    .overlay(Circle().stroke(.white, lineWidth: 3))
                    .shadow(color: tint.opacity(0.45), radius: 7, y: 3)
                Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
            }
            Image(systemName: "arrowtriangle.down.fill").font(.system(size: 13)).foregroundStyle(tint)
        }
        .onAppear {
            guard pulsing else { return }
            withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) { pulse = true }
        }
        .accessibilityHidden(true)
    }
}

/// Secondary circular action next to a primary button (Fitts: large, separated targets).
struct RoundIconButton: View {
    let symbol: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColors.ink)
                .frame(width: 56, height: 56)
                .background(AppColors.ink.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
