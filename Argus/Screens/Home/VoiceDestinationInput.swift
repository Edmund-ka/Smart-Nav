import AVFAudio
import Combine
import Speech
import UIKit

// One explicit listening session. Cancellation also invalidates pending permission requests.
final class VoiceDestinationInput: ObservableObject {
    @Published private(set) var listening = false
    @Published private(set) var preparing = false
    @Published private(set) var transcript = ""
    @Published var message: String?
    var onResult: ((String) -> Void)?
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var timeout: Task<Void, Never>?
    // Changing this ID makes callbacks from a cancelled permission/listening session harmless.
    private var session = UUID()
    private var tapped = false

    /// Ask for permissions, attach microphone audio to recognition, and listen for at most 12 seconds.
    func start() async {
        cancel()
        let id = UUID()
        session = id
        preparing = true
        transcript = ""
        message = nil
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard session == id else { return }
        guard speech == .authorized else {
            preparing = false
            message = "Allow Speech Recognition in Settings, or choose a destination from the list."
            return
        }
        let microphone = await AVAudioApplication.requestRecordPermission()
        guard session == id else { return }
        guard microphone else {
            preparing = false
            message = "Allow microphone access in Settings, or choose a destination from the list."
            return
        }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")), recognizer.isAvailable else {
            preparing = false
            message = "Speech recognition is unavailable. Try again or choose a destination."
            return
        }
        do {
            let audio = AVAudioSession.sharedInstance()
            try audio.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try audio.setActive(true)
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            self.request = request
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else { throw CocoaError(.featureUnsupported) }
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in request.append(buffer) }
            tapped = true
            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    guard let self, self.session == id else { return }
                    if let result { self.transcript = result.bestTranscription.formattedString }
                    if result?.isFinal == true {
                        self.finish()
                    } else if error != nil {
                        self.message = "Listening ended. Try again or choose a destination."
                        self.cancel()
                    }
                }
            }
            engine.prepare()
            try engine.start()
            preparing = false
            listening = true
            if UserDefaults.standard.object(forKey: "guidanceHaptics") as? Bool ?? true {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            timeout = Task { [weak self] in
                do { try await Task.sleep(for: .seconds(12)) } catch { return }
                self?.finish()
            }
        } catch {
            cancel()
            message = "The microphone could not start. Try again or choose a destination."
        }
    }

    /// Send the latest recognized words to Home only after ending microphone capture.
    func finish() {
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        cancel()
        if text.isEmpty { message = "I didn’t catch that. Try again or choose a destination." } else { onResult?(text) }
    }

    /// Release this session’s tap, recognition task, and timeout. Safe to call repeatedly.
    func cancel() {
        let ownedAudioSession = tapped || engine.isRunning
        session = UUID()
        timeout?.cancel()
        timeout = nil
        engine.stop()
        if tapped {
            engine.inputNode.removeTap(onBus: 0)
            tapped = false
        }
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        listening = false
        preparing = false
        if ownedAudioSession {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}
