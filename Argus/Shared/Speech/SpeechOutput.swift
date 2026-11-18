import AVFAudio
import Combine
import UIKit

/// Gives Home and both replay screens the same speech and VoiceOver behavior.
final class SpeechOutput: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()

    /// Speak one instruction at the user's preferred rate, replacing any previous instruction.
    func speak(_ message: String, rate: Double) {
        stop()
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: message)
            return
        }

        // Lower other audio while the instruction plays; do not capture microphone input here.
        let audio = AVAudioSession.sharedInstance()
        try? audio.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? audio.setActive(true)
        let utterance = AVSpeechUtterance(string: message)
        utterance.rate = Float(rate)
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
