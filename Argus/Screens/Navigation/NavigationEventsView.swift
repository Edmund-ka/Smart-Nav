import SwiftUI

/// The event log always distinguishes observations from an expected-event comparison.
struct NavigationEventsView: View {
    @Environment(\.dismiss) private var dismiss
    let session: NavigationSession
    let expected: [ExpectedNavigationEvent]?
    var body: some View {
        List {
            Section("Evaluation") {
                Text("\(session.source.rawValue) · \(session.route.graphID) · \(session.route.graphVersion)")
                Text("\(session.acceptedReadings) accepted · \(session.rejectedReadings) rejected readings")
                if let expected {
                    Text(
                        NavigationEvaluation.compare(
                            expected: expected, actual: session.events, kinds: Set(expected.map(\.kind))
                        ).summary)
                    Text("Expected times come from manual marks; they are not surveyed ground truth.").font(.caption)
                } else {
                    Text("Event log only. No independent expected-event annotations supplied.")
                }
                ShareLink("Share event log", item: report)
            }
            Section("Events in sensor time") {
                ForEach(session.events) { event in
                    VStack(alignment: .leading) {
                        Text(event.message)
                        Text(
                            "\(event.time.formatted(date: .omitted, time: .standard)) · \(Int(event.progressMeters)) m"
                        ).font(.caption)
                        if let distance = event.distanceToDecision {
                            Text("Decision distance: \(Int(distance)) m").font(.caption)
                        }
                    }
                }
            }
        }.navigationTitle("Evaluation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
    }
    private var report: String {
        ([
            "Argus \(session.source.rawValue) evaluation",
            "Dataset: \(session.route.graphID) / \(session.route.graphVersion)",
        ]
            + session.events.map {
                "\($0.time.timeIntervalSince1970) | \($0.kind.rawValue) | \($0.progressMeters) m | \($0.message)"
            }).joined(separator: "\n")
    }
}
