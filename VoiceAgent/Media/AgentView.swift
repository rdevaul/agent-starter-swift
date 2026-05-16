import SwiftUI
import UIKit

/// A view that shows the agent's audio visualizer with smooth, real-time audio levels.
struct AgentView: View {
    @EnvironmentObject private var session: VoiceSession

    @Environment(\.namespace) private var namespace

    /// Smoothed audio levels for each bar
    @State private var barLevels: [Float] = [0, 0, 0, 0, 0]

    var body: some View {
        ZStack {
            HStack(spacing: 4 * .grid) {
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: 8, height: maxHeight(for: i))
                        .animation(.interpolatingSpring(stiffness: 200, damping: 12), value: barLevels[i])
                }
            }
            .frame(maxWidth: 75 * .grid, maxHeight: 48 * .grid)
        }
        .matchedGeometryEffect(id: "agent", in: namespace!)
        .onReceive(updateBarLevels) { levels in
            barLevels = levels
        }
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

    /// Generates 5 smoothed bar levels from the single audio level measurement
    private var updateBarLevels: AnyPublisher<[Float], Never> {
        session.$audioLevel
            .map { [previousLevels = [Float](repeating: 0, count: 5)] audioLevel -> [Float] in
                var levels = previousLevels
                let newLevels = [Float](repeating: 0, count: 5)
                // Distribute audio level across 5 bars with slight variation
                for i in 0..<5 {
                    let weight = 1.0 - abs(Float(i) - 2.0) * 0.15
                    let target = audioLevel * weight * (0.8 + Float.random(in: 0...0.4))
                    // Smooth: interpolate towards target
                    levels[i] += (target - levels[i]) * 0.4
                    levels[i] = max(0, levels[i])
                }
                return levels
            }
            .eraseToAnyPublisher()
    }
}
