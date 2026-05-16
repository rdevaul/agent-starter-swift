import Foundation
import Combine

@MainActor
final class VoiceSession: ObservableObject {

    enum State: Equatable {
        case idle
        case connecting
        case recording
        case processing
        case speaking
        case error(String)
    }

    @Published var state: State = .idle
    @Published var transcript: String = ""
    @Published var error: String?
    @Published var audioLevel: Float = 0.0

    let audioEngine = AudioEngineManager()

    private let client: VoiceAPIClient
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.client = VoiceAPIClient()

        // Mirror audioEngine level into session
        audioEngine.$audioLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.audioLevel = level
            }
            .store(in: &cancellables)

        client.setEventHandler { [weak self] event in
            DispatchQueue.main.async {
                self?.handleEvent(event)
            }
        }
    }

    func connect(to serverURL: String) async {
        guard let url = URL(string: serverURL) else {
            error = "Invalid server URL"
            state = .error("Invalid server URL")
            return
        }
        do {
            try await audioEngine.setup()
        } catch {
            self.error = "Audio setup failed: \(error.localizedDescription)"
            state = .error("Audio setup failed: \(error.localizedDescription)")
            return
        }
        await client.connect(to: url)
    }

    func disconnect() {
        client.disconnect()
        audioEngine.stopCapture()
        state = .idle
    }

    func startRecording() {
        state = .recording
        audioEngine.setAudioDataCallback { [weak self] buffer in
            self?.client.sendAudio(buffer.data)
        }
        client.startRecording()
    }

    func stopRecording() {
        state = .processing
        audioEngine.stopCapture()
        client.stopRecording()
    }

    private func handleEvent(_ event: VoiceAPIClient.Event) {
        switch event {
        case .ready:
            state = .idle
        case .transcript(let text):
            transcript = text
            state = .processing
        case .thinking(let isThinking):
            state = isThinking ? .processing : .idle
        case .audioEnd:
            state = .idle
        case .audioChunk(let data):
            state = .speaking
            Task { await audioEngine.playAudio(data: data) }
            state = .idle
        case .error(let message):
            error = message
            state = .error(message)
        case .disconnected:
            state = .idle
        }
    }
}
