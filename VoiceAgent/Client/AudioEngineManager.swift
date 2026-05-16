import AVFoundation
import Accelerate
import Foundation

@MainActor
final class AudioEngineManager: ObservableObject {

    @Published var audioLevel: Float = 0.0
    @Published var isRunning: Bool = false

    private var audioEngine: AVAudioEngine?
    private var audioDataCallback: ((AVAudioPCMBuffer) -> Void)?

    func setup() async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth, .allowAirPlay])
        try session.setActive(true)

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)

        engine.prepare()
        try engine.start()
        audioEngine = engine
        isRunning = true

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            let channelData = buffer.floatChannelData?[0]
            if let channelData = channelData {
                var rms: Float = 0
                vDSP_magnitude(channelData, vDSP.Stride(1), &rms, vDSP.Length(buffer.frameLength))
                self.audioLevel = min(rms * 10.0, 1.0)
            }
            self.audioDataCallback?(buffer)
        }
    }

    func setAudioDataCallback(_ callback: @escaping (AVAudioPCMBuffer) -> Void) {
        audioDataCallback = callback
    }

    func stopCapture() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        audioDataCallback = nil
        isRunning = false
        audioLevel = 0.0
    }

    func playAudio(data: Data) async {
        guard let engine = audioEngine else { return }
        let player = AVAudioPlayerNode()
        engine.attach(player)

        let format = engine.outputNode.outputFormat(forBus: 0)
        let floatCount = data.count / MemoryLayout<Float>.size
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(floatCount)) else { return }
        buffer.frameLength = buffer.frameCapacity
        buffer.floatChannelData?[0].update(from: data, count: floatCount)

        engine.connect(player, to: engine.mainMixerNode!, format: format)
        player.scheduleBuffer(buffer)
        player.play()

        while player.isPlaying {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        engine.detach(player)
    }
}
