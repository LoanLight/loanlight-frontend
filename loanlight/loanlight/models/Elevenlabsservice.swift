import Foundation
import AVFoundation
import Combine

// MARK: - Playback State

enum TTSPlaybackState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case error(String)
}

// MARK: - ElevenLabs TTS Service

@MainActor
final class ElevenLabsService: NSObject, ObservableObject {
    // ↑ ObservableObject already synthesizes objectWillChange automatically —
    //   never declare it manually or you'll get "no initializers" errors.

    // ─── Config ──────────────────────────────────────────────────────────────
    private let apiKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "ELEVENLABS_API_KEY") as? String,
              !key.isEmpty,
              key != "your_elevenlabs_api_key_here" else {
            assertionFailure("""
            ⚠️  ElevenLabs API key not configured.
            1. Copy Secrets.xcconfig.template → Secrets.xcconfig
            2. Paste your key from elevenlabs.io/profile
            3. Assign Secrets.xcconfig to your target in Xcode (Project → Info → Configurations)
            4. Add ELEVENLABS_API_KEY to Info.plist as a string entry
            """)
            return ""
        }
        return key
    }()

    private let voiceID = "21m00Tcm4TlvDq8ikWAM"
    private let modelID = "eleven_turbo_v2"

    // ─── State ────────────────────────────────────────────────────────────────
    @Published var playbackState: TTSPlaybackState = .idle
    @Published var currentLessonID: String? = nil

    private var audioPlayer: AVAudioPlayer?
    private var audioData: Data?
    private var task: Task<Void, Never>?

    // ─── Public API ───────────────────────────────────────────────────────────

    func toggle(lesson: Lesson) {
        if currentLessonID == lesson.id {
            switch playbackState {
            case .playing:  pause()
            case .paused:   resume()
            default:        break
            }
        } else {
            stop()
            currentLessonID = lesson.id
            speak(text: buildScript(for: lesson))
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        audioPlayer?.stop()
        audioPlayer = nil
        audioData = nil
        playbackState = .idle
        currentLessonID = nil
    }

    // ─── Private ──────────────────────────────────────────────────────────────

    private func pause() {
        audioPlayer?.pause()
        playbackState = .paused
    }

    private func resume() {
        audioPlayer?.play()
        playbackState = .playing
    }

    private func speak(text: String) {
        task = Task {
            do {
                playbackState = .loading
                let data = try await fetchAudio(text: text)
                guard !Task.isCancelled else { return }
                audioData = data
                try play(data: data)
            } catch {
                guard !Task.isCancelled else { return }
                playbackState = .error(error.localizedDescription)
            }
        }
    }

    private func fetchAudio(text: String) async throws -> Data {
        let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceID)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")

        let body: [String: Any] = [
            "text": text,
            "model_id": modelID,
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.8,
                "style": 0.0,
                "use_speaker_boost": true
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw TTSError.invalidResponse
        }
        guard http.statusCode == 200 else {
            let msg = (try? JSONDecoder().decode(ElevenLabsError.self, from: data))?.detail.message
                      ?? "HTTP \(http.statusCode)"
            throw TTSError.apiError(msg)
        }
        return data
    }

    private func play(data: Data) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
        try session.setActive(true)

        audioPlayer = try AVAudioPlayer(data: data, fileTypeHint: "mp3")
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
        playbackState = .playing
    }

    private func buildScript(for lesson: Lesson) -> String {
        var parts: [String] = []
        parts.append(lesson.title)
        parts.append(lesson.promise)
        parts.append(lesson.bodyText)
        parts.append("Key Takeaways.")
        parts.append(contentsOf: lesson.keyTakeaways.enumerated().map { i, t in "\(i + 1). \(t)" })
        return parts.joined(separator: ". ")
    }
}

// MARK: - AVAudioPlayerDelegate

extension ElevenLabsService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.playbackState = .idle
            self.currentLessonID = nil
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            self.playbackState = .error(error?.localizedDescription ?? "Decode error")
        }
    }
}

// MARK: - Error Types

enum TTSError: LocalizedError {
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:  return "Invalid response from ElevenLabs."
        case .apiError(let m):  return m
        }
    }
}

private struct ElevenLabsError: Decodable {
    struct Detail: Decodable { let message: String }
    let detail: Detail
}
