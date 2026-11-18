import Foundation

struct ExpectedNavigationEvent {
    let kind: NavigationEvent.Kind
    let earliest: Date
    let latest: Date
}

/// One-to-one matching prevents one actual event from satisfying multiple expected events.
struct NavigationEvaluation {
    let matched: Int
    let missing: [NavigationEvent.Kind]
    let unexpected: [NavigationEvent]
    let outsideWindow: [NavigationEvent]
    var summary: String {
        "\(matched) matched · \(missing.count) missing · \(unexpected.count) unexpected · \(outsideWindow.count) outside timing window"
    }

    static func compare(
        expected: [ExpectedNavigationEvent], actual: [NavigationEvent], kinds: Set<NavigationEvent.Kind>
    ) -> Self {
        var remaining = actual.filter { kinds.contains($0.kind) }
        var matched = 0
        var missing: [NavigationEvent.Kind] = []
        var late: [NavigationEvent] = []
        var unmatched: [ExpectedNavigationEvent] = []
        for target in expected.sorted(by: { $0.latest < $1.latest }) {
            if let i = remaining.indices.filter({
                remaining[$0].kind == target.kind && remaining[$0].time >= target.earliest
                    && remaining[$0].time <= target.latest
            }).min(by: { remaining[$0].time < remaining[$1].time }) {
                matched += 1
                remaining.remove(at: i)
            } else {
                unmatched.append(target)
            }
        }
        // Do not consume an event outside one window if it can satisfy another expectation.
        for target in unmatched {
            if let i = remaining.indices.filter({ remaining[$0].kind == target.kind }).min(by: {
                abs(remaining[$0].time.timeIntervalSince(target.earliest))
                    < abs(remaining[$1].time.timeIntervalSince(target.earliest))
            }) {
                late.append(remaining.remove(at: i))
            } else {
                missing.append(target.kind)
            }
        }
        return Self(matched: matched, missing: missing, unexpected: remaining, outsideWindow: late)
    }
}
