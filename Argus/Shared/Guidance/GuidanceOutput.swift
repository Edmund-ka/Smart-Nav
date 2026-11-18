import Combine
import SwiftUI

/// Reuses SpeechOutput. Events map to documented iOS feedback patterns and respect the user's preference.
final class GuidanceOutput: ObservableObject {
    private let speech = SpeechOutput()
    // Keep navigation events in the log while the shared audio session belongs to voice input.
    var isListening = false
    private var pulseTask: Task<Void, Never>?
    func announce(_ events: [NavigationEvent]) {
        guard !isListening, !events.isEmpty else { return }
        let rate = UserDefaults.standard.object(forKey: "speechRate") as? Double ?? 0.5
        // Combine same-fix messages so a reroute cannot immediately cancel its departure announcement.
        speech.speak(events.map(\.message).joined(separator: " "), rate: rate)
        guard UserDefaults.standard.object(forKey: "guidanceHaptics") as? Bool ?? true, let kind = events.last?.kind
        else { return }
        pulseTask?.cancel()
        switch kind {
        case .arrived: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .offRoute, .noRoute: UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .uncertain, .crossing, .accessibility, .demonstration:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .turnLeft: UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .turnRight:
            // Two medium pulses distinguish right from left; device/user testing is still required.
            pulseTask = Task { @MainActor in
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                do { try await Task.sleep(for: .milliseconds(220)) } catch { return }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        default: UISelectionFeedbackGenerator().selectionChanged()
        }
    }
    func repeatMessage(_ message: String) {
        speech.speak(message, rate: UserDefaults.standard.object(forKey: "speechRate") as? Double ?? 0.5)
    }
    func stop() {
        pulseTask?.cancel()
        speech.stop()
    }
}
