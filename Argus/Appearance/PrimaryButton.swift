import SwiftUI

/// Gives the main action on every page the same type, shape, and touch target.
struct PrimaryButton: View {
    let title: String
    let icon: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.poppins(.headline, weight: .semibold)).frame(maxWidth: .infinity, minHeight: 56)
                .foregroundStyle(AppColors.ink).background(AppColors.accent, in: RoundedRectangle(cornerRadius: 18))
        }.buttonStyle(.plain)
    }
}
