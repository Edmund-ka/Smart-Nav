import SwiftUI

/// Touch-based fallback for selecting an origin or destination without speech.
struct PlacePickerView: View {
    let choosingStart: Bool
    let selectedID: String?
    var choose: (CampusPlace?) -> Void
    @EnvironmentObject private var maps: CampusMapStore
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @AppStorage("favoritePlaces") private var favorites = ""
    private var places: [CampusPlace] {
        CampusPlace.available(in: maps.graph)
            .filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }
            .sorted { first, second in
                let firstSaved = SavedPlaces.contains(first.id, in: favorites)
                let secondSaved = SavedPlaces.contains(second.id, in: favorites)
                if firstSaved != secondSaved { return firstSaved }
                return first.name < second.name
            }
    }
    var body: some View {
        NavigationStack {
            List {
                Group {
                    if choosingStart {
                        Button {
                            choose(nil)
                            dismiss()
                        } label: {
                            Label("Current location", systemImage: "location.fill")
                        }
                    }
                    Section(choosingStart ? "Campus starting points" : "Campus destinations") {
                        ForEach(places) { place in
                            Button {
                                choose(place)
                                dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: place.icon).font(.poppins(.title2)).frame(width: 36)
                                        .accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(place.name).font(.poppins(.headline))
                                        Text(place.detail).font(.poppins(.caption)).foregroundStyle(
                                            AppColors.secondaryInk)
                                    }
                                    Spacer()
                                    if selectedID == place.id {
                                        Image(systemName: "checkmark").accessibilityLabel("Selected")
                                    } else if SavedPlaces.contains(place.id, in: favorites) {
                                        Image(systemName: "star.fill").accessibilityLabel("Saved place")
                                    }
                                }.padding(.vertical, 8)
                            }.foregroundStyle(.primary)
                        }
                    }
                }.listRowBackground(GlassBackground(shape: Rectangle()))
            }.glassListCanvas()
                .searchable(text: $search, prompt: "Find a mapped entrance")
                .navigationTitle(choosingStart ? "Starting point" : "Where to?")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}
