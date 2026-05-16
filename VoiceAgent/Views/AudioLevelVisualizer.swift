import SwiftUI

struct AudioLevelVisualizer: View {
    let level: Float
    let state: VoiceSession.State

    var barColor: Color {
        switch state {
        case .recording: return .green
        case .processing: return .orange
        case .speaking: return .blue
        case .idle, .connecting: return .gray.opacity(0.4)
        case .error: return .red
        }
    }

    var maxHeight: CGFloat {
        max(CGFloat(level) * 40, 2)
    }

    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(barColor)
                .frame(width: 8, height: maxHeight)
                .animation(.easeOut(duration: 0.1), value: level)
        }
        .frame(maxHeight: 40)
    }
}

#Preview {
    HStack(spacing: 4) {
        ForEach(0..<5) { _ in
            AudioLevelVisualizer(level: Float.random(in: 0.2...0.8), state: .recording)
        }
    }
}
