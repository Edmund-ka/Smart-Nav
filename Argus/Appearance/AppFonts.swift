import CoreText
import SwiftUI

/// Registers Poppins once and applies it to native navigation and segmented controls.
enum AppFonts {
    static func registerFonts() {
        // Bundle the actual font so the design also works without an internet connection.
        for weight in ["Regular", "SemiBold", "Bold"] {
            if let url = Bundle.main.url(forResource: "Poppins-\(weight)", withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
        let navigation = UINavigationBar.appearance()
        navigation.largeTitleTextAttributes = [
            .font: scaledFont("Poppins-Bold", size: 34, style: .largeTitle), .foregroundColor: UIColor(AppColors.ink),
        ]
        navigation.titleTextAttributes = [
            .font: scaledFont("Poppins-SemiBold", size: 17, style: .headline),
            .foregroundColor: UIColor(AppColors.ink),
        ]
        UISegmentedControl.appearance().setTitleTextAttributes(
            [
                .font: scaledFont("Poppins-SemiBold", size: 13, style: .footnote)
            ], for: .normal)
    }

    private static func scaledFont(_ name: String, size: CGFloat, style: UIFont.TextStyle) -> UIFont {
        UIFontMetrics(forTextStyle: style).scaledFont(for: UIFont(name: name, size: size) ?? .systemFont(ofSize: size))
    }
}

extension Font {
    /// Match iOS text styles while allowing Dynamic Type to scale the bundled font.
    static func poppins(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        let size: CGFloat
        switch style {
        case .largeTitle: size = 34
        case .title: size = 28
        case .title2: size = 22
        case .title3: size = 20
        case .headline, .body: size = 17
        case .callout: size = 16
        case .subheadline: size = 15
        case .footnote: size = 13
        case .caption: size = 12
        case .caption2: size = 11
        @unknown default: size = 17
        }
        let face =
            weight == .bold || weight == .heavy
            ? "Bold" : weight == .semibold || weight == .medium ? "SemiBold" : "Regular"
        return .custom("Poppins-\(face)", size: size, relativeTo: style)
    }
}
