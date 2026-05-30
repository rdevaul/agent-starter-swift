import SwiftUI

/// Simplified control bar with audio and disconnect controls.
struct ControlBar: View {
    @EnvironmentObject private var session: VoiceSession

    private enum Constants {
        static let buttonWidth: CGFloat = 16 * .grid
        static let buttonHeight: CGFloat = 11 * .grid
    }

    var body: some View {
        HStack(spacing: .zero) {
            biggerSpacer()
            audioControls()
            flexibleSpacer()
            disconnectButton()
            biggerSpacer()
        }
        .buttonStyle(
            ControlBarButtonStyle(
                foregroundColor: .fg1,
                backgroundColor: .bg2,
                borderColor: .separator1
            )
        )
        .font(.system(size: 17, weight: .medium))
        .frame(height: 15 * .grid)
        #if !os(visionOS)
            .overlay(
                RoundedRectangle(cornerRadius: 7.5 * .grid)
                    .stroke(.separator1, lineWidth: 1)
            )
            .background(
                RoundedRectangle(cornerRadius: 7.5 * .grid)
                    .fill(.bg1)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 10)
            )
            .safeAreaPadding(.bottom, 8 * .grid)
            .safeAreaPadding(.horizontal, 16 * .grid)
        #endif
    }

    private func flexibleSpacer() -> some View {
        Spacer()
            .frame(maxWidth: 8 * .grid)
    }

    private func biggerSpacer() -> some View {
        Spacer()
            .frame(maxWidth: 8 * .grid)
    }

    private func audioControls() -> some View {
        HStack(spacing: .zero) {
            Spacer()
            Button {
                switch session.state {
                case .recording:
                    session.stopRecording()
                case .idle:
                    session.startRecording()
                default:
                    break
                }
            } label: {
                HStack(spacing: .grid) {
                    Image(systemName: session.state == .recording ? "microphone.fill" : "microphone.slash.fill")
                        .transition(.symbolEffect)
                    Spacer()
                }
                .frame(height: Constants.buttonHeight)
                .padding(.horizontal, 2 * .grid)
                .contentShape(Rectangle())
            }
            .padding(.vertical, 2 * .grid)
            Spacer()
        }
        .frame(width: Constants.buttonWidth)
    }

    private func disconnectButton() -> some View {
        Button {
            session.disconnect()
        } label: {
            Image(systemName: "phone.down.fill")
                .frame(width: Constants.buttonWidth, height: Constants.buttonHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(
            ControlBarButtonStyle(
                foregroundColor: .fgSerious,
                backgroundColor: .bgSerious,
                borderColor: .separatorSerious
            )
        )
    }
}
