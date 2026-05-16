import SwiftUI

/// The initial view that is shown when the app is not connected to the server.
struct StartView: View {
    @EnvironmentObject private var session: VoiceSession

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var serverURL: String = ""

    var body: some View {
        VStack(spacing: 8 * .grid) {
            titleSection()
            urlField()
            connectButton()
        }
        .padding(.horizontal, horizontalSizeClass == .regular ? 32 * .grid : 16 * .grid)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, content: tip)
        #if os(visionOS)
            .glassBackgroundEffect()
            .frame(maxWidth: 175 * .grid)
        #endif
    }

    private func titleSection() -> some View {
        VStack(spacing: 4 * .grid) {
            bars()
            Text("Voice Assistant")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.fg0)
        }
    }

    private func bars() -> some View {
        HStack(spacing: .grid) {
            let bars = [2, 8, 12, 8, 2].map { $0 * .grid }
            ForEach(0 ..< 5, id: \.self) { index in
                Rectangle()
                    .fill(.fg0)
                    .frame(width: 2 * .grid, height: bars[index])
            }
        }
    }

    private func urlField() -> some View {
        TextField("Server URL", text: $serverURL)
            .textFieldStyle(.plain)
            .foregroundStyle(.fg1)
            .padding(2 * .grid)
            .background(.bg2)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusSmall))
            .frame(maxWidth: horizontalSizeClass == .regular ? 80 * .grid : .infinity)
    }

    private func tip() -> some View {
        VStack(spacing: 2 * .grid) {
            #if targetEnvironment(simulator)
                Text("connect.simulator")
                    .foregroundStyle(.fgModerate)
            #endif
            Text("connect.tip")
                .foregroundStyle(.fg3)
        }
        .font(.system(size: 12))
        .multilineTextAlignment(.center)
        .safeAreaPadding(.horizontal, horizontalSizeClass == .regular ? 32 * .grid : 16 * .grid)
        .safeAreaPadding(.vertical)
    }

    @ViewBuilder
    private func connectButton() -> some View {
        Button {
            Task {
                await session.connect(to: serverURL)
            }
        } label: {
            HStack {
                Spacer()
                Text("connect.start")
                Spacer()
            }
            .frame(width: 58 * .grid, height: 11 * .grid)
        }
        .buttonStyle(ProminentButtonStyle())
        .disabled(serverURL.isEmpty)
    }
}

#Preview {
    StartView()
}
