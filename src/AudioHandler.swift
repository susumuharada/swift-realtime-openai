//
//  File.swift
//  OpenAIRealtime
//
//  Created by Susumu Harada on 6/4/25.
//

import Foundation
@preconcurrency import AVFoundation

final class AudioHandler: @unchecked Sendable {
    var onAudioDeltaFromUser: (Data) -> Void = { _ in }

    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let queuedSamples = UnsafeMutableArray<String>()
    private let apiConverter = UnsafeInteriorMutable<AVAudioConverter>()
    private let userConverter = UnsafeInteriorMutable<AVAudioConverter>()
    private let desiredFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 24000, channels: 1, interleaved: false)!

    @MainActor public private(set) var isInterrupting: Bool = false

    /// Whether the conversation is currently listening to the user's microphone.
    @MainActor public private(set) var isListening: Bool = false

    /// Whether this conversation is currently handling voice input and output.
    @MainActor public private(set) var handlingVoice: Bool = false

    /// Whether the model is currently speaking.
    @MainActor public private(set) var isPlaying: Bool = false

    @MainActor public var audioTimeInMilliseconds: Int? {
        guard let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else {
            return nil
        }
        let audioTimeInMiliseconds = Int((Double(playerTime.sampleTime) / playerTime.sampleRate) * 1000)
        return audioTimeInMiliseconds
    }

    @MainActor public var oldestQueuedSampleID: String? {
        queuedSamples.first
    }

    init() {
        _keepIsPlayingPropertyUpdated()
    }

    /// Start listening to the user's microphone and sending audio data to the model.
    /// This will automatically call `startHandlingVoice` if it hasn't been called yet.
    /// > Warning: Make sure to handle the case where the user denies microphone access.
    @MainActor func startListening() throws {
        guard !isListening else { return }
        print("AudioHandler startListening")
        if !handlingVoice { try startHandlingVoice() }

        Task.detached { [audioEngine] in
            audioEngine.inputNode.installTap(onBus: 0, bufferSize: 4096, format: audioEngine.inputNode.outputFormat(forBus: 0)) { [weak self] buffer, _ in
                self?.processAudioBufferFromUser(buffer: buffer)
            }
        }

        isListening = true
    }

    /// Stop listening to the user's microphone.
    /// This won't stop playing back model responses. To fully stop handling voice conversations, call `stopHandlingVoice`.
    @MainActor func stopListening() {
        guard isListening else { return }
        print("AudioHandler stopListening")
        audioEngine.inputNode.removeTap(onBus: 0)
        isListening = false
    }

    /// Handle the playback of audio responses from the model.
    @MainActor func startHandlingVoice() throws {
        guard !handlingVoice else { return }
        print("AudioHandler startHandlingVoice")

        guard let converter = AVAudioConverter(from: audioEngine.inputNode.outputFormat(forBus: 0), to: desiredFormat) else {
            throw ConversationError.converterInitializationFailed
        }
        userConverter.set(converter)

        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: converter.inputFormat)

#if os(iOS)
        try audioEngine.inputNode.setVoiceProcessingEnabled(true)
#endif

        audioEngine.prepare()
        do {
            try audioEngine.start()

#if os(iOS)
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try audioSession.setActive(true)
#endif

            handlingVoice = true
        } catch {
            print("Failed to enable audio engine: \(error)")

            audioEngine.disconnectNodeInput(playerNode)
            audioEngine.disconnectNodeOutput(playerNode)

            throw error
        }
    }

    /// Interrupt the model's response if it's currently playing.
    /// This lets the model know that the user didn't hear the full response.
    @MainActor func interruptSpeech(_ perform: (AudioHandler) -> Void) {
        guard !isInterrupting else { return }
        print("AudioHandler interruptSpeech")
        isInterrupting = true

        perform(self)

        playerNode.stop()
        queuedSamples.clear()
        isInterrupting = false
    }

    @MainActor func stopHandlingVoice() {
        guard handlingVoice else { return }
        print("AudioHandler stopHandlingVoice")

        Self.cleanUpAudio(playerNode: playerNode, audioEngine: audioEngine)

        isListening = false
        handlingVoice = false
    }

    /// Stop playing audio responses from the model and listening to the user's microphone.
    static func cleanUpAudio(playerNode: AVAudioPlayerNode, audioEngine: AVAudioEngine) {
        // If attachedNodes does not contain the playerNode then `startHandlingVoice` was never called
        guard audioEngine.attachedNodes.contains(playerNode) else { return }

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        audioEngine.disconnectNodeInput(playerNode)
        audioEngine.disconnectNodeOutput(playerNode)

#if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false)
#elseif os(macOS)
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.reset()
        }
#endif
    }

    func queueAudioSample(_ event: ServerEvent.ResponseAudioDeltaEvent) {
        guard let buffer = AVAudioPCMBuffer.fromData(event.delta, format: desiredFormat) else {
            print("Failed to create audio buffer.")
            return
        }

        guard let converter = apiConverter.lazy({ AVAudioConverter(from: buffer.format, to: playerNode.outputFormat(forBus: 0)) }) else {
            print("Failed to create audio converter.")
            return
        }

        let outputFrameCapacity = AVAudioFrameCount(ceil(converter.outputFormat.sampleRate / buffer.format.sampleRate) * Double(buffer.frameLength))

        guard let sample = convertBuffer(buffer: buffer, using: converter, capacity: outputFrameCapacity) else {
            print("Failed to convert buffer.")
            return
        }

        queuedSamples.push(event.itemId)

        playerNode.scheduleBuffer(sample, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            guard let self else { return }

            self.queuedSamples.popFirst()
            if self.queuedSamples.isEmpty {
                Task { @MainActor in
                    playerNode.pause()
                }
            }
        }

        playerNode.play()
    }
}

/// Audio processing private API
extension AudioHandler {
    private func processAudioBufferFromUser(buffer: AVAudioPCMBuffer) {
        let ratio = desiredFormat.sampleRate / buffer.format.sampleRate

        guard let convertedBuffer = convertBuffer(buffer: buffer, using: userConverter.get()!, capacity: AVAudioFrameCount(Double(buffer.frameLength) * ratio)) else {
            print("Buffer conversion failed.")
            return
        }

        guard let sampleBytes = convertedBuffer.audioBufferList.pointee.mBuffers.mData else { return }
        let audioData = Data(bytes: sampleBytes, count: Int(convertedBuffer.audioBufferList.pointee.mBuffers.mDataByteSize))

        onAudioDeltaFromUser(audioData)
//        Task {
//            try await send(audioDelta: audioData)
//        }
    }

    private func convertBuffer(buffer: AVAudioPCMBuffer, using converter: AVAudioConverter, capacity: AVAudioFrameCount) -> AVAudioPCMBuffer? {
        if buffer.format == converter.outputFormat {
            return buffer
        }

        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: capacity) else {
            print("Failed to create converted audio buffer.")
            return nil
        }

        var error: NSError?
        var allSamplesReceived = false

        let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
            if allSamplesReceived {
                outStatus.pointee = .noDataNow
                return nil
            }

            allSamplesReceived = true
            outStatus.pointee = .haveData
            return buffer
        }

        if status == .error {
            if let error = error {
                print("Error during conversion: \(error.localizedDescription)")
            }
            return nil
        }

        return convertedBuffer
    }
}

// Other private methods
extension AudioHandler {
    /// This hack is required because relying on `queuedSamples.isEmpty` directly crashes the app.
    /// This is because updating the `queuedSamples` array on a background thread will trigger a re-render of any views that depend on it on that thread.
    /// So, instead, we observe the property and update `isPlaying` on the main actor.
    private func _keepIsPlayingPropertyUpdated() {
        withObservationTracking { _ = queuedSamples.isEmpty } onChange: {
            Task { @MainActor [weak self] in
                guard let self else { return }

                self.isPlaying = self.queuedSamples.isEmpty
                self._keepIsPlayingPropertyUpdated()
            }
        }
    }
}
