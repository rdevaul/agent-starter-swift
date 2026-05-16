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
    private var eventHandler: ((Event) -> Void)?
    private var sessionId: String

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForConnection = 30
        urlSession = URLSession(configuration: config)
        sessionId = UserDefaults.standard.string(forKey: "voiceSessionId") ?? UUID().uuidString
        if UserDefaults.standard.string(forKey: "voiceSessionId") == nil {
            UserDefaults.standard.set(sessionId, forKey: "voiceSessionId")
        }
    }

    func setEventHandler(_ handler: @escaping (Event) -> Void) { eventHandler = handler }

    func connect(to url: URL) async {
        guard connectionState == .disconnected else { return }
        connectionState = .connecting
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        connectionState = .connected
        eventHandler?(.ready)
        receiveMessages()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        connectionState = .disconnected
        eventHandler?(.disconnected)
    }

    func sendAudio(_ data: Data) {
        webSocketTask?.send(.data(data)) { error in
            if let error = error {
                self.eventHandler?(.error("Audio send failed: \(error.localizedDescription)"))
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
        webSocketTask?.send(.string(string)) { error in
            if let error = error {
                self.eventHandler?(.error("Send failed: \(error.localizedDescription)"))
            }
        }
    }

    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                self.handleMessage(message)
                self.receiveMessages()
            case .failure:
                self.connectionState = .disconnected
                self.eventHandler?(.disconnected)
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data): eventHandler?(.audioChunk(data))
        case .string(let text):
            guard let d = text.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                  let type = json["type"] as? String else { return }
            switch type {
            case "transcript": eventHandler?(.transcript(json["text"] as? String ?? ""))
            case "thinking": eventHandler?(.thinking(json["thinking"] as? Bool ?? true))
            case "audio_end": eventHandler?(.audioEnd)
            case "error": eventHandler?(.error(json["message"] as? String ?? "Unknown error"))
            default: break
            }
        @unknown default: break
        }
    }
}
