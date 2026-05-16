import SwiftUI

/// A view that shows the agent's audio visualizer with smooth, real-time audio levels.
struct AgentView: View {
    @EnvironmentObject private var session: VoiceSession

    @Environment(\.namespace) private var namespace

    @State private var barLevels: [Float] = [0, 0, 0, 0, 0]

    var body: some View {
        ZStack {
            HStack(spacing: 4 * .grid) {
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: 8, height: maxHeight(for: i))
                }
            }
            .frame(maxWidth: 75 * .grid, maxHeight: 48 * .grid)
            .onReceive(session.$audioLevel) { newLevel in
                updateBarLevels(newLevel)
            }
        }
        .matchedGeometryEffect(id: "agent", in: namespace!)
    }

    private var barColor: Color {
        switch session.state {
        case .recording: return .green
        case .processing: return .orange
        case .speaking: return .blue
        case .idle, .connecting: return .gray.opacity(0.4)
        case .error: return .red
        }
    }

    private func maxHeight(for index: Int) -> CGFloat {
        let level = CGFloat(barLevels[index])
        return max(level * 60, 4)
    }

    private func updateBarLevels(_ audioLevel: Float) {
        for i in 0..<5 {
            let weight = 1.0 - abs(Float(i) - 2.0) * 0.15
            let target = audioLevel * weight * (0.8 + Float.random(in: 0...0.4))
            barLevels[i] += (target - barLevels[i]) * 0.4
            barLevels[i] = max(0, barLevels[i])
        }
    }
}
