import SwiftUI

/// Shared bottom navigation. Home embeds it inside its card; other tabs use a bottom inset.
struct AppTabBar: View {
    @Binding var selection: AppTab
    @EnvironmentObject private var recorder: WalkRecorder
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.home, "Home", "location.north")
            tabButton(.simulate, "Simulate", "map")
            tabButton(.record, recorder.recording ? "Recording" : "Record", "record.circle")
            tabButton(.profile, "Profile", "person.crop.circle")
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .padding(.bottom, 0)
    }

    private func tabButton(_ tab: AppTab, _ title: String, _ symbol: String) -> some View {
        let selected = selection == tab
        return Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .symbolVariant(selected ? .fill : .none)
                    .font(.title3)
                if !dynamicTypeSize.isAccessibilitySize {
                    Text(title).font(.poppins(.caption2, weight: selected ? .semibold : .regular))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(AppColors.ink.opacity(selected ? 1 : 0.7))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) tab")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

}
