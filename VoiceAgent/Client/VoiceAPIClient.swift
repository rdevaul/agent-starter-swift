import Foundation

final class VoiceAPIClient: ObservableObject {
    enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
        case error(String)
    }

    enum Event {
        case ready
        case transcript(String)
        case thinking(Bool)
        case audioEnd
        case audioChunk(Data)
        case error(String)
        case disconnected
    }

    @Published var connectionState: ConnectionState = .disconnected

    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession: URLSession
    private let callbackQueue = DispatchQueue(label: "com.glados.voice.callback")
    private var eventHandler: ((Event) -> Void)?
    private var sessionId: String

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        urlSession = URLSession(configuration: config)
        sessionId = UserDefaults.standard.string(forKey: "voiceSessionId") ?? UUID().uuidString
        if UserDefaults.standard.string(forKey: "voiceSessionId") == nil {
            UserDefaults.standard.set(sessionId, forKey: "voiceSessionId")
        }
    }

    func setEventHandler(_ handler: @escaping (Event) -> Void) {
        eventHandler = handler
    }

    @MainActor
    private func fireEvent(_ event: Event) {
        eventHandler?(event)
    }

    func connect(to url: URL) async {
        guard connectionState == .disconnected else { return }
        connectionState = .connecting
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        connectionState = .connected
        await fireEvent(.ready)
        Task { await receiveMessages() }
    }

    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        connectionState = .disconnected
        Task { @MainActor in await fireEvent(.disconnected) }
    }

    func sendAudio(_ data: Data) {
        webSocketTask?.send(.data(data)) { [weak self] error in
            if let error = error {
                Task { @MainActor in self?.fireEvent(.error("Audio send failed: \(error.localizedDescription)")) }
            }
        }
    }

    func startRecording() {
        sendControlMessage(["type": "start_recording"])
    }

    func stopRecording() {
        sendControlMessage(["type": "stop_recording"])
    }

    private func sendControlMessage(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let string = String(data: data, encoding: .utf8) else { return }
        webSocketTask?.send(.string(string)) { [weak self] error in
            if let error = error {
                Task { @MainActor in self?.fireEvent(.error("Send failed: \(error.localizedDescription)")) }
            }
        }
    }

    private func receiveMessages() async {
        guard let task = webSocketTask else { return }
        do {
            let message = try await task.receive()
            handleMessage(message)
            Task { await receiveMessages() }
        } catch {
            await MainActor.run { [weak self] in
                self?.connectionState = .disconnected
                Task { await self?.fireEvent(.disconnected) }
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            Task { @MainActor in fireEvent(.audioChunk(data)) }
        case .string(let text):
            guard let d = text.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                  let type = json["type"] as? String else { return }
            switch type {
            case "transcript":
                Task { @MainActor in fireEvent(.transcript(json["text"] as? String ?? "")) }
            case "thinking":
                Task { @MainActor in fireEvent(.thinking(json["thinking"] as? Bool ?? true)) }
            case "audio_end":
                Task { @MainActor in fireEvent(.audioEnd) }
            case "error":
                Task { @MainActor in fireEvent(.error(json["message"] as? String ?? "Unknown error")) }
            default: break
            }
        @unknown default: break
        }
    }
}
