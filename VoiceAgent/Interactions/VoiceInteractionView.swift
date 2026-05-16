import SwiftUI

struct VoiceInteractionView: View {
    @EnvironmentObject private var session: VoiceSession

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            regular()
        } else {
            compact()
        }
    }

    private func regular() -> some View {
        HStack {
            Spacer()
                .frame(width: 50 * .grid)
            AgentView()
            Spacer()
                .frame(width: 50 * .grid)
        }
        .safeAreaPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func compact() -> some View {
        ZStack(alignment: .bottom) {
            AgentView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        }
    }
}
