import SwiftUI

struct AppView: View {
    @EnvironmentObject private var session: VoiceSession
    @FocusState private var keyboardFocus: Bool
    @Namespace private var namespace

    var body: some View {
        ZStack(alignment: .top) {
            if session.state != .idle && session.state != .error("Not connected") {
                interactions()
            } else {
                start()
            }

            errors()
        }
        .environment(\.namespace, namespace)
        .safeAreaInset(edge: .bottom) {
                if session.state != .idle && session.state != .error("Not connected"), !keyboardFocus {
                    ControlBar()
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .background(.bg1)
            .animation(.default, value: session.state)
            .animation(.default, value: session.error)
            .sensoryFeedback(.impact, trigger: session.state)
    }

    private func start() -> some View {
        StartView()
    }

    @ViewBuilder
    private func interactions() -> some View {
        VoiceInteractionView()
            .overlay(alignment: .bottom) {
                agentListening()
                    .padding()
            }
    }

    @ViewBuilder
    private func errors() -> some View {
        if let error = session.error {
            ErrorView(error: error) { session.error = nil }
        }
    }

    private func agentListening() -> some View {
        ZStack {
            if session.state == .idle {
                Text("agent.listening")
                    .font(.system(size: 15))
                    .shimmering()
                    .transition(.blurReplace)
            }
        }
        .animation(.default, value: session.state)
    }
}
