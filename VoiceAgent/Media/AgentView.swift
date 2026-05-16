import SwiftUI

/// A view that shows the agent's audio visualizer.
struct AgentView: View {
    @EnvironmentObject private var session: VoiceSession

    @Environment(\.namespace) private var namespace
    /// Reveals the avatar video view when true (reserved for future video support).
    @SceneStorage("videoTransition") private var videoTransition = false

    var body: some View {
        ZStack {
            switch session.state {
            case .speaking, .processing:
                ForEach(0..<5) { i in
                    AudioLevelVisualizer(
                        level: session.state == .speaking ? Float.random(in: 0.3...0.9) : Float.random(in: 0.1...0.3),
                        state: session.state
                    )
                }
                .frame(maxWidth: 75 * .grid, maxHeight: 48 * .grid)
                .transition(.opacity)
            case .recording:
                ForEach(0..<5) { _ in
                    AudioLevelVisualizer(level: Float.random(in: 0.2...0.8), state: .recording)
                }
                .frame(maxWidth: 75 * .grid, maxHeight: 48 * .grid)
                .transition(.opacity)
            case .idle, .connecting:
                AudioLevelVisualizer(level: 0.1, state: .idle)
                    .frame(maxWidth: 75 * .grid, maxHeight: 48 * .grid)
                    .transition(.opacity)
            case .error:
                AudioLevelVisualizer(level: 0.1, state: .error)
                    .frame(maxWidth: 75 * .grid, maxHeight: 48 * .grid)
                    .transition(.opacity)
            }
        }
        .matchedGeometryEffect(id: "agent", in: namespace!)
    }
}
