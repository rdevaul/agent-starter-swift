import SwiftUI

@main
struct VoiceAgentApp: App {
    @StateObject private var session = VoiceSession()
    private let serverURL = "wss://voice-api.rich.dev:8444/ws/voice"

    var body: some Scene {
        WindowGroup {
            AppView()
                .environmentObject(session)
        }
        #if os(macOS)
        .defaultSize(width: 900, height: 900)
        #endif
        #if os(visionOS)
        .windowStyle(.plain)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1500, height: 500)
        #endif
    }
}
