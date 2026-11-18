import MapKit
import SwiftUI

/// Reads the latest saved walk by ID so renames and deletions update this screen.
struct WalkDetailView: View {
    let walkID: UUID
    @EnvironmentObject private var recorder: WalkRecorder
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var renaming = false
    @State private var deleting = false
    private var walk: WalkData? { recorder.walks.first { $0.id == walkID } }
    var body: some View {
        Group {
            if let walk {
                List {
                    Group {
                        Section {
                            Map {
                                MapPolyline(coordinates: walk.readings.map(\.coordinate)).stroke(
                                    AppColors.accent, lineWidth: 4)
                                if let first = walk.readings.first {
                                    Marker("Start", coordinate: first.coordinate).tint(.green)
                                }
                                if let last = walk.readings.last { Marker("Finish", coordinate: last.coordinate) }
                            }.frame(height: 230).clipShape(RoundedRectangle(cornerRadius: 16))
                                .accessibilityLabel("Recorded walk map. Measurements follow below.")
                            Text(walk.title).font(.poppins(.title, weight: .bold))
                            Text(walk.started.formatted()).foregroundStyle(AppColors.secondaryInk)
                        }
                        Section {
                            LabeledContent(
                                "Duration",
                                value: Duration.seconds(walk.duration).formatted(.time(pattern: .minuteSecond)))
                            LabeledContent("Estimated distance", value: "\(Int(walk.measuredDistance)) m")
                            LabeledContent("GPS fixes", value: "\(walk.readings.count)")
                            if let mean = walk.meanReportedAccuracy {
                                LabeledContent("Mean reported GPS accuracy", value: "±\(Int(mean)) m")
                            }
                            LabeledContent("Motion samples", value: walk.motion.map { "\($0.count)" } ?? "Unavailable")
                            LabeledContent(
                                "Compass samples", value: walk.compass.map { "\($0.count)" } ?? "Unavailable")
                        } header: {
                            Text("Measurements")
                        } footer: {
                            Text(
                                "Distance is estimated from GPS after excluding poor fixes and implausible jumps. Reported GPS accuracy is not independently measured position error."
                            )
                        }
                        if let marks = walk.marks, !marks.isEmpty {
                            Section("Event marks") {
                                ForEach(Array(marks.enumerated()), id: \.offset) { _, mark in
                                    LabeledContent(
                                        mark.label, value: "\(Int(mark.time.timeIntervalSince(walk.started))) s")
                                }
                            }
                        }
                        Section {
                            NavigationLink {
                                WalkReplayView(walk: walk, exportURL: recorder.fileURL(for: walk))
                            } label: {
                                Label("Replay recorded walk", systemImage: "play.circle")
                            }
                            ShareLink(item: recorder.fileURL(for: walk)) {
                                Label("Export walk data", systemImage: "square.and.arrow.up")
                            }
                            Button("Rename walk", systemImage: "pencil") {
                                name = walk.name ?? ""
                                renaming = true
                            }
                            Button("Delete walk", role: .destructive) { deleting = true }
                        }
                        if let message = recorder.message, !message.isEmpty { Text(message).font(.poppins(.caption)) }
                    }.listRowBackground(GlassBackground(shape: Rectangle()))
                }.glassListCanvas()
                    .alert("Rename walk", isPresented: $renaming) {
                        TextField("Walk name", text: $name)
                        Button("Save") { recorder.rename(walk, to: name) }
                        Button("Cancel", role: .cancel) {}
                    }
                    .confirmationDialog("Delete this saved walk?", isPresented: $deleting, titleVisibility: .visible) {
                        Button("Delete walk", role: .destructive) {
                            recorder.delete(walk)
                            if !recorder.walks.contains(where: { $0.id == walkID }) { dismiss() }
                        }
                    }
            } else {
                ContentUnavailableView("Walk unavailable", systemImage: "figure.walk")
            }
        }.navigationTitle("Walk details").navigationBarTitleDisplayMode(.inline)
    }
}
