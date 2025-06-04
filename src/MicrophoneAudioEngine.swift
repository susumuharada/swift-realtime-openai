import Foundation
@preconcurrency import AVFoundation
import Combine
import OSLog

extension AVAudioFormat {

    /// 1 channel, 16000Hz, Int16
    static let rt_monoInt16KHzFormat = AVAudioFormat(settings: [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVSampleRateKey: 16000.0,
        AVNumberOfChannelsKey: 1,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsBigEndianKey: false,
        AVLinearPCMIsNonInterleaved: true
    ])!

    /// 1 channel, 16000Hz, Float32
    static let rt_monoFloat16KHzFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!

    static let rt_openAIFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 24000, channels: 1, interleaved: false)!
}

/// !!CAUTION!! Due to voice processing behavior, MicrophoneAudioEngine must be initialized before playback engine
class MicrophoneAudioEngine {

    private let audioEngine = AVAudioEngine()
    private let mixer: AVAudioMixerNode
    private let audioSink: AVAudioSinkNode!
    private var muteUntilDate: Date? = nil

    /// Audio buffer can be retrieved from this by `sink()`
    let audioPublisher = PassthroughSubject<AVAudioPCMBuffer, Never>()
    enum  MicrophoneAudioEngineError : Error{
        case unableToCreateBuffer
    }

    /// The audio format that the engine produces.
    let audioFormat: AVAudioFormat

    init() throws {

        // block variables
        let audioPublisher = self.audioPublisher

        // enable echo cancellation by default
        try audioEngine.inputNode.setVoiceProcessingEnabled(true)

        let voiceProcessingFormat = audioEngine.inputNode.outputFormat(forBus: 0)

        // based on this: https://developer.apple.com/videos/play/wwdc2019/510
        // installTap isn't suitable for realtime IO due to delay
        audioSink = AVAudioSinkNode(receiverBlock: { _, _, bufferList in
            guard let buffer = AVAudioPCMBuffer(pcmFormat: voiceProcessingFormat, bufferListNoCopy: bufferList) else {
                Logger.audio.error("Unable to create AVAudioPCMBuffer")
                return 1
            }

            do {
                let monoBuffer = try buffer.convertTo(.rt_openAIFormat)
                audioPublisher.send(monoBuffer)
                return 0
            } catch {
                Logger.audio.error("Unable to convert buffer to LEF 16kHz Mono")
                return 1
            }
        })

        // build graph
        mixer = AVAudioMixerNode()
        audioEngine.attach(audioSink)
        audioEngine.attach(mixer)
        audioEngine.connect(audioEngine.inputNode, to: mixer, format: voiceProcessingFormat)
        audioEngine.connect(mixer, to: audioSink, format: voiceProcessingFormat)

        // TODO: implement a custom node that converts any audio to mono 16k audio
        // possibly 2 nodes, one to merge channels into mono channel, another to do simple conversion

        Logger.audio.info("Voice processing AU format: \(voiceProcessingFormat)")
        audioFormat = voiceProcessingFormat
    }

    func start() throws {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleConfigChange(_:)),
                                               name: .AVAudioEngineConfigurationChange,
                                               object: nil)

        try audioEngine.start()
        #if os(iOS)
        // Move it here to workaround weird bluetooth issue. See detail in git history and its PR.
        // This is for iOS only - on macOS, once this is called, mic will not pick up audio (rdar://151511541 (App (RTS) live audio doesn't work in macOS anymore))
        _ = audioEngine.mainMixerNode // trick to suppress render error
        #endif
    }

    func stop() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .AVAudioEngineConfigurationChange,
                                                  object: nil)
        audioEngine.stop()
    }

    @objc
    private func handleConfigChange(_ nofitication: Notification) {
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch {
                Logger.audio.error("Cannot start microphone engine upon audio config change, error:\(error)")
            }
        }
    }
}

extension AVAudioPCMBuffer {

    enum AudioConversionError: Error {
        case failedToCreateConverter
        case failedToCreateBuffer
        case failedToConvertData
    }

    func convertTo(_ outputFormat: AVAudioFormat) throws -> AVAudioPCMBuffer {
        guard let converter = AVAudioConverter(from: self.format, to: outputFormat) else {
            Logger.audio.error("Failed to initialize AVAudioConverter.")
            throw AudioConversionError.failedToCreateConverter
        }
        let newFrameCapacity = AVAudioFrameCount(Double(self.frameLength) * (outputFormat.sampleRate / self.format.sampleRate))
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: newFrameCapacity) else {
            Logger.audio.error("Failed to create output buffer.")
            throw AudioConversionError.failedToCreateBuffer
        }


        if self.format.channelCount > 1 {
            converter.channelMap = Array(repeating: NSNumber(0), count: Int(self.format.channelCount)) // Mix all input channels into channel 0
        }

        var error: NSError? = nil
        let conversionStatus = converter.convert(to: outputBuffer, error: &error, withInputFrom: {_, outStatus in
            outStatus.pointee = .haveData
            return self
        })
        if let error = error {
            Logger.audio.error("Conversion failed: \(error)")
            throw AudioConversionError.failedToConvertData
        }

        if conversionStatus != .haveData {
            Logger.audio.error("Conversion did not produce full data.")
        }

        return outputBuffer
    }
}
