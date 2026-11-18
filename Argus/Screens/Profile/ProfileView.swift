import PhotosUI
import SwiftUI

/// User preferences, photo selection, and expandable explanations live together on this tab.
struct ProfileView: View {
    @EnvironmentObject private var profile: ProfilePhotoStore
    @State private var photo: PhotosPickerItem?
    @AppStorage("profileName") private var name = ""
    @AppStorage("speechRate") private var speechRate = 0.5
    @AppStorage("guidanceHaptics") private var haptics = true
    @StateObject private var speaker = SpeechOutput()

    var body: some View {
        NavigationStack {
            Form {
                Group {
                    Section {
                        VStack(spacing: Spacing.s) {
                            // The camera badge is the photo control, so the header needs no extra buttons.
                            ProfilePhotoView(size: 88)
                                .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                                .shadow(color: AppColors.ink.opacity(0.15), radius: 8, y: 4)
                                .overlay(alignment: .bottomTrailing) {
                                    PhotosPicker(selection: $photo, matching: .images) {
                                        Image(systemName: "camera.fill").font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(.white).frame(width: 32, height: 32)
                                            .background(AppColors.accent, in: Circle())
                                            .overlay(Circle().strokeBorder(.white, lineWidth: 2.5))
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Choose profile photo")
                                }
                            Text(name.isEmpty ? "Your Argus" : name).font(.poppins(.title2, weight: .bold))
                            Text("Stays on this iPhone · no account needed")
                                .font(.poppins(.caption)).foregroundStyle(AppColors.secondaryInk)
                            if profile.image != nil {
                                Button("Remove photo", role: .destructive) { profile.setPhoto(nil) }
                                    .font(.poppins(.caption, weight: .semibold)).buttonStyle(.borderless)
                            }
                        }.frame(maxWidth: .infinity).padding(.vertical, Spacing.m)
                        LabeledContent {
                            TextField("Optional", text: $name).textContentType(.nickname)
                                .multilineTextAlignment(.trailing)
                        } label: {
                            BadgeLabel(title: "Display name", symbol: "person.fill", tint: AppColors.accent)
                        }
                        if let error = profile.photoError { Text(error).foregroundStyle(.red) }
                    }
                    Section("Accessibility & guidance") {
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            HStack {
                                BadgeLabel(title: "Speech rate", symbol: "speaker.wave.2.fill", tint: .indigo)
                                Spacer()
                                Button("Hear sample", systemImage: "play.circle.fill") {
                                    speaker.speak("In about 20 meters, turn right.", rate: speechRate)
                                }
                                .font(.poppins(.caption, weight: .semibold)).buttonStyle(.borderless)
                            }
                            // Tortoise and hare make the slider's direction obvious without reading.
                            Slider(value: $speechRate, in: 0.35...0.65, step: 0.05) {
                                Text("Speech rate")
                            } minimumValueLabel: {
                                Image(systemName: "tortoise.fill").accessibilityHidden(true)
                            } maximumValueLabel: {
                                Image(systemName: "hare.fill").accessibilityHidden(true)
                            }
                            .accessibilityValue(speechRate < 0.5 ? "Slower" : speechRate > 0.5 ? "Faster" : "Normal")
                        }
                        .padding(.vertical, 4)
                        Toggle(isOn: $haptics) {
                            BadgeLabel(
                                title: "Vibration feedback", symbol: "iphone.radiowaves.left.and.right", tint: .orange)
                        }
                        .tint(AppColors.accent)
                        DisclosureGroup {
                            InformationPage(
                                icon: "mic.fill",
                                paragraphs: [
                                    "On Home, tap the voice field and say ‘Take me to the library’ or ‘Take me to Boyd Hall.’ The route appears on the Home map. Tap Start guidance, or tap the microphone and say ‘start’.",
                                    "During guidance, tap the microphone and say ‘repeat’, ‘where am I’, or ‘stop navigation’. The play button next to Start runs a labelled simulated walk.",
                                    "Use the From menu to choose your current location or a campus starting point. Apple Maps is an explicit fallback in the Home menu.",
                                    "Listening starts only when you ask. Speech recognition may need an internet connection. Continuous wake-word and locked-screen voice control are not available yet.",
                                ])
                        } label: {
                            BadgeLabel(title: "Voice command guide", symbol: "mic.fill", tint: AppColors.ink)
                        }
                    }
                    Section("Tools") {
                        NavigationLink {
                            CampusDataView()
                        } label: {
                            BadgeLabel(title: "Campus map data", symbol: "map.fill", tint: .green)
                        }
                        NavigationLink {
                            SavedPlacesView()
                        } label: {
                            BadgeLabel(title: "Saved places", symbol: "star.fill", tint: .yellow)
                        }
                        NavigationLink {
                            SensorDashboardView().navigationTitle("Sensors").navigationBarTitleDisplayMode(.inline)
                        } label: {
                            BadgeLabel(title: "Sensors", symbol: "waveform.path.ecg", tint: .red)
                        }
                        DisclosureGroup {
                            InformationPage(
                                icon: "eyeglasses",
                                paragraphs: [
                                    "Glasses and Apple Watch integration are planned. Argus currently uses this iPhone for recording and presentation playback.",
                                    "Bluetooth pairing alone does not enable camera or navigation integration.",
                                ])
                        } label: {
                            BadgeLabel(title: "Connected devices", symbol: "eyeglasses", tint: .teal)
                        }
                    }
                    Section("Support") {
                        DisclosureGroup {
                            InformationPage(
                                icon: "hand.raised.fill",
                                paragraphs: [
                                    "Profile photos and saved walks are stored in this app on your iPhone. Delete saved walks from Record. Remove your photo from Profile.",
                                    "Recording collects GPS and reported accuracy, plus available motion and compass measurements. Keep Argus open while recording; background recording is not supported yet.",
                                    "Exports share the data you select. Speech recognition may send audio to Apple for processing. Map tiles use network services. Argus graph routes are calculated locally.",
                                ])
                        } label: {
                            BadgeLabel(title: "Privacy & storage", symbol: "hand.raised.fill", tint: .blue)
                        }
                        DisclosureGroup {
                            InformationPage(
                                icon: "map.fill",
                                paragraphs: [
                                    "Home currently offers the library and Boyd Hall as campus destinations. Argus calculates paths from the selected campus graph. The bundled trace and imported candidate paths do not verify accessible entrances, stairs, obstacles or current closures. Live guidance is available on the walk-reviewed Boyd Hall to library route; GPS positions near buildings remain approximate.",
                                    "Simulate uses an approximate Boyd Hall–library route traced from campus imagery. It is a presentation demonstration, not live guidance.",
                                    "Argus does not detect obstacles or determine when it is safe to cross a street. Continue using your normal mobility aids.",
                                ])
                        } label: {
                            BadgeLabel(
                                title: "Coverage & limitations", symbol: "exclamationmark.triangle.fill", tint: .orange)
                        }
                        LabeledContent {
                            Text("1.0 · Campus preview")
                        } label: {
                            BadgeLabel(title: "Version", symbol: "info", tint: .gray)
                        }
                    }
                }.listRowBackground(GlassBackground(shape: Rectangle()))
            }.glassListCanvas().navigationTitle("Profile")
                // A new selection replaces the previous photo-loading task.
                .task(id: photo) {
                    guard let photo else { return }
                    do {
                        if let data = try await photo.loadTransferable(type: Data.self) {
                            profile.setPhoto(data)
                        } else {
                            profile.photoError = "This photo could not be opened."
                        }
                    } catch { profile.photoError = "This photo could not be opened. Please try another." }
                }
        }
    }
}
