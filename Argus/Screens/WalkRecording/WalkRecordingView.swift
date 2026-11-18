import MapKit
import SwiftUI

/// Recording controls and saved walks share the recorder owned by MainTabView.
struct WalkRecordingView: View {
    @EnvironmentObject private var maps: CampusMapStore
    @EnvironmentObject private var recorder: WalkRecorder
    @State private var walkName = ""
    @State private var deleting: WalkData?
    @State private var discard = false

    // Decode the bundled reference once; it is not a new recording from this phone.
    private static let sample: WalkData? = {
        guard let url = Bundle.main.url(forResource: "BoydWalkSample", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode(WalkData.self, from: data)
    }()

    var body: some View {
        NavigationStack {
            List {
                Group {
                    Section {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: Spacing.m) {
                                IconBadge(
                                    symbol: recorder.recording
                                        ? "record.circle.fill" : recorder.draft != nil ? "checkmark" : "figure.walk",
                                    tint: recorder.recording
                                        ? .red : recorder.draft != nil ? GuidanceStep.success : AppColors.accent,
                                    size: 44
                                )
                                .symbolEffect(.pulse, isActive: recorder.recording)
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(
                                        recorder.recording
                                            ? "Recording your walk"
                                            : recorder.draft != nil ? "Save this walk?" : "New walk"
                                    )
                                    .font(.poppins(.title3, weight: .bold)).accessibilityAddTraits(.isHeader)
                                    Text("GPS, distance and movement for route evaluation")
                                        .font(.poppins(.caption)).foregroundStyle(AppColors.secondaryInk)
                                }
                            }
                            if let walk = recorder.draft {
                                if recorder.recording {
                                    TimelineView(.periodic(from: .now, by: 1)) { context in
                                        metrics(walk, duration: context.date.timeIntervalSince(walk.started))
                                    }
                                    Menu {
                                        ForEach(["Turn", "Left route", "Rejoined route", "Arrived"], id: \.self) {
                                            label in
                                            Button(label) { recorder.mark(label) }
                                        }
                                    } label: {
                                        Label("Mark an event", systemImage: "flag.fill").frame(minHeight: 48)
                                    }
                                    if let mark = walk.marks?.last {
                                        Text("Last mark: \(mark.label)").font(.poppins(.caption))
                                    }
                                    PrimaryButton(title: "Stop recording", icon: "stop.fill") { recorder.stop() }
                                } else {
                                    metrics(walk, duration: walk.duration)
                                    TextField("Walk name (optional)", text: $walkName).textFieldStyle(.roundedBorder)
                                    PrimaryButton(title: "Save walk", icon: "checkmark") {
                                        recorder.save(name: walkName)
                                        if recorder.draft == nil { walkName = "" }
                                    }
                                    Button("Discard recording", role: .destructive) { discard = true }.frame(
                                        minHeight: 44)
                                }
                            } else {
                                PrimaryButton(title: "Start recording", icon: "record.circle") {
                                    recorder.start(graph: maps.graph)
                                }
                            }
                            if let message = recorder.message, !message.isEmpty {
                                Text(message).font(.poppins(.callout)).foregroundStyle(AppColors.secondaryInk)
                            }
                        }.padding(.vertical, 12)
                    } footer: {
                        VStack(alignment: .leading, spacing: 6) {
                            tip("iphone", "Keep Argus open; leaving the app stops capture.")
                            tip("square.grid.2x2", "Switching tabs is fine.")
                            tip("lock.fill", "Walks stay on this iPhone.")
                        }
                        .padding(.top, 4)
                    }
                    Section("Saved walks") {
                        if recorder.walks.isEmpty {
                            ContentUnavailableView(
                                "No saved walks", systemImage: "figure.walk",
                                description: Text("Saved routes and metrics will appear here."))
                        }
                        ForEach(recorder.walks) { walk in
                            NavigationLink {
                                WalkDetailView(walkID: walk.id)
                            } label: {
                                HStack(spacing: Spacing.m) {
                                    IconBadge(
                                        symbol: "point.topleft.down.to.point.bottomright.curvepath.fill",
                                        tint: AppColors.ink)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(walk.title).font(.poppins(.headline))
                                        Text(
                                            "\(Int(walk.duration / 60)) min · \(Int(walk.measuredDistance)) m · \(walk.readings.count) fixes"
                                        )
                                        .font(.poppins(.caption)).foregroundStyle(AppColors.secondaryInk)
                                    }
                                }.padding(.vertical, 6)
                            }
                            .swipeActions { Button("Delete", role: .destructive) { deleting = walk } }
                        }
                    }
                    if let sample = Self.sample, !recorder.walks.contains(where: { $0.id == sample.id }) {
                        Section("Reference recording") {
                            NavigationLink {
                                WalkReplayView(walk: sample, exportURL: nil)
                            } label: {
                                BadgeLabel(
                                    title: "Boyd Hall to library · recorded GPS", symbol: "play.circle.fill",
                                    tint: AppColors.accent)
                            }
                        }
                    }
                }.listRowBackground(GlassBackground(shape: Rectangle()))
            }.glassListCanvas().navigationTitle("Record")
                .confirmationDialog("Discard this unsaved recording?", isPresented: $discard, titleVisibility: .visible)
            {
                Button("Discard recording", role: .destructive) {
                    recorder.discard()
                    walkName = ""
                }
            }
                .confirmationDialog(
                    "Delete this saved walk?",
                    isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
                    titleVisibility: .visible
                ) {
                    Button("Delete walk", role: .destructive) {
                        if let walk = deleting { recorder.delete(walk) }
                        deleting = nil
                    }
                }

        }
    }

    private func metrics(_ walk: WalkData, duration: TimeInterval) -> some View {
        HStack(spacing: Spacing.s) {
            StatTile(
                value: Duration.seconds(max(0, duration)).formatted(.time(pattern: .minuteSecond)), label: "Elapsed")
            StatTile(value: "\(walk.readings.count)", label: "GPS fixes")
            StatTile(value: walk.readings.last.map { "±\(Int($0.accuracyMeters)) m" } ?? "—", label: "Accuracy")
        }
    }

    private func tip(_ symbol: String, _ text: String) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: symbol).frame(width: 18)
        }
        .font(.poppins(.caption))
    }
}
