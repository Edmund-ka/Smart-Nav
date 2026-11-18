import SwiftUI

/// Supporting profile content: saved-place switches and inline help text.
struct SavedPlacesView: View {
    @AppStorage("favoritePlaces") private var favorites = ""
    var body: some View {
        List {
            Group {
                ForEach(CampusPlace.places) { place in
                    Toggle(
                        isOn: Binding(
                            get: {
                                SavedPlaces.contains(place.id, in: favorites)
                            },
                            set: { saved in
                                favorites = SavedPlaces.updating(place.id, saved: saved, in: favorites)
                            })
                    ) { Label(place.name, systemImage: place.icon) }
                }
            }.listRowBackground(GlassBackground(shape: Rectangle()))
        }.glassListCanvas().navigationTitle("Saved places").navigationBarTitleDisplayMode(.inline)
    }
}

/// Inline help content reused by Profile disclosure sections.
struct InformationPage: View {
    let icon: String
    let paragraphs: [String]
    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon).font(.poppins(.largeTitle)).foregroundStyle(AppColors.accent)
                    .accessibilityHidden(true)
                ForEach(paragraphs, id: \.self) {
                    Text($0).font(.poppins(.body)).fixedSize(horizontal: false, vertical: true)
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(24)
        }
    }
}
