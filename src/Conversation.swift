import Foundation
@preconcurrency import AVFoundation
import OSLog

public enum ConversationError: Error {
	case sessionNotFound
	case converterInitializationFailed
}

@Observable
public final class Conversation: @unchecked Sendable {
	private let client: RealtimeAPI
    @MainActor private var isInterrupting: Bool {
        audioHandler.isInterrupting
    }
	private let errorStream: AsyncStream<ServerError>.Continuation

	private var task: Task<Void, Error>!

	/// A stream of errors that occur during the conversation.
	public let errors: AsyncStream<ServerError>

	/// The unique ID of the conversation.
	@MainActor public private(set) var id: String?

	/// The current session for this conversation.
	@MainActor public private(set) var session: Session?

	/// A list of items in the conversation.
	@MainActor public private(set) var entries: [Item] = []

	/// Whether the conversation is currently connected to the server.
	@MainActor public private(set) var connected: Bool = false

	/// Whether the conversation is currently listening to the user's microphone.
    @MainActor public var isListening: Bool {
        audioHandler.isListening
    }

	/// Whether this conversation is currently handling voice input and output.
    @MainActor public var handlingVoice: Bool {
        audioHandler.handlingVoice
    }

	/// Whether the user is currently speaking.
	/// This only works when using the server's voice detection.
	@MainActor public var isUserSpeaking: Bool = false

	/// Whether the model is currently speaking.
    @MainActor public var isPlaying: Bool {
        audioHandler.isPlaying
    }

	/// A list of messages in the conversation.
	/// Note that this doesn't include function call events. To get a complete list, use `entries`.
	@MainActor public var messages: [Item.Message] {
		entries.compactMap { switch $0 {
			case let .message(message): return message
			default: return nil
		} }
	}

    private let audioHandler = AudioHandler()

	private init(client: RealtimeAPI) {
		self.client = client
		(errors, errorStream) = AsyncStream.makeStream(of: ServerError.self)

		let events = client.events
		task = Task.detached { [weak self] in
			for try await event in events {
				guard !Task.isCancelled else { break }

				await self?.handleEvent(event)
			}

			await MainActor.run { [weak self] in
				self?.connected = false
			}
		}

		Task { @MainActor in
			client.onDisconnect = { [weak self] in
				guard let self else { return }

				Task { @MainActor in
					self.connected = false
				}
			}
		}

        audioHandler.onAudioDeltaFromUser = { audioData in
            Task { [weak self] in
                try await self?.send(audioDelta: audioData)
            }
        }
	}

	deinit {
		task.cancel()
		errorStream.finish()
	}

	/// Create a new conversation providing an API token and, optionally, a model.
	public convenience init(authToken token: String, model: String = "gpt-4o-realtime-preview") {
		self.init(client: RealtimeAPI.webSocket(authToken: token, model: model))
	}

	/// Create a new conversation that connects using a custom `URLRequest`.
	public convenience init(connectingTo request: URLRequest) {
		self.init(client: RealtimeAPI.webSocket(connectingTo: request))
	}

	/// Wait for the connection to be established
	@MainActor public func waitForConnection() async {
		while true {
			if connected {
				return
			}

			try? await Task.sleep(for: .milliseconds(500))
		}
	}

	/// Execute a block of code when the connection is established
	@MainActor public func whenConnected<E>(_ callback: @Sendable () async throws(E) -> Void) async throws(E) {
		await waitForConnection()
		try await callback()
	}

	/// Make changes to the current session
	/// Note that this will fail if the session hasn't started yet. Use `whenConnected` to ensure the session is ready.
	public func updateSession(withChanges callback: (inout Session) -> Void) async throws {
		guard var session = await session else {
			throw ConversationError.sessionNotFound
		}

		callback(&session)

		try await setSession(session)
	}

	/// Set the configuration of the current session
	public func setSession(_ session: Session) async throws {
		// update endpoint errors if we include the session id
		var session = session
		session.id = nil

		try await client.send(event: .updateSession(session))
	}

	/// Send a client event to the server.
	/// > Warning: This function is intended for advanced use cases. Use the other functions to send messages and audio data.
	public func send(event: ClientEvent) async throws {
		try await client.send(event: event)
	}

	/// Manually append audio bytes to the conversation.
	/// Commit the audio to trigger a model response when server turn detection is disabled.
	/// > Note: The `Conversation` class can automatically handle listening to the user's mic and playing back model responses.
	/// > To get started, call the `startListening` function.
	public func send(audioDelta audio: Data, commit: Bool = false) async throws {
		try await send(event: .appendInputAudioBuffer(encoding: audio))
		if commit { try await send(event: .commitInputAudioBuffer()) }
	}

	/// Send a text message and wait for a response.
	/// Optionally, you can provide a response configuration to customize the model's behavior.
	/// > Note: Calling this function will automatically call `interruptSpeech` if the model is currently speaking.
	public func send(from role: Item.ItemRole, text: String, response: Response.Config? = nil) async throws {
		if await handlingVoice { await interruptSpeech() }

		try await send(event: .createConversationItem(Item(message: Item.Message(id: String(randomLength: 32), from: role, content: [.input_text(text)]))))
		try await send(event: .createResponse(response))
	}

	/// Send the response of a function call.
	public func send(result output: Item.FunctionCallOutput) async throws {
		try await send(event: .createConversationItem(Item(with: output)))
	}
}

/// Listening/Speaking public API
public extension Conversation {
	/// Start listening to the user's microphone and sending audio data to the model.
	/// This will automatically call `startHandlingVoice` if it hasn't been called yet.
	/// > Warning: Make sure to handle the case where the user denies microphone access.
	@MainActor func startListening() throws {
        try audioHandler.startListening()
	}

	/// Stop listening to the user's microphone.
	/// This won't stop playing back model responses. To fully stop handling voice conversations, call `stopHandlingVoice`.
	@MainActor func stopListening() {
        audioHandler.stopListening()
	}

	/// Handle the playback of audio responses from the model.
	@MainActor func startHandlingVoice() throws {
        try audioHandler.startHandlingVoice()
	}

	/// Interrupt the model's response if it's currently playing.
	/// This lets the model know that the user didn't hear the full response.
	@MainActor func interruptSpeech() {
        audioHandler.interruptSpeech { audioHandler in
            if isPlaying,
               let audioTimeInMiliseconds = audioHandler.audioTimeInMilliseconds,
               let itemID = audioHandler.oldestQueuedSampleID
            {
                Task { [client] in
                    do {
                        Logger.conversation.log("Sending truncateConversationItem")
                        try await client.send(event: .truncateConversationItem(forItem: itemID, atAudioMs: audioTimeInMiliseconds))
                    } catch {
                        Logger.conversation.error("Failed to send automatic truncation event: \(error)")
                    }
                }
            }
        }
	}

	@MainActor func stopHandlingVoice() {
        audioHandler.stopHandlingVoice()
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
}

/// Event handling private API
private extension Conversation {
	@MainActor func handleEvent(_ event: ServerEvent) {
        Logger.conversation.log("Handling event:\n\(event.debugDescription)")
		switch event {
			case let .error(event):
				errorStream.yield(event.error)
			case let .sessionCreated(event):
				connected = true
				session = event.session
			case let .sessionUpdated(event):
				session = event.session
			case let .conversationCreated(event):
				id = event.conversation.id
			case let .conversationItemCreated(event):
				entries.append(event.item)
			case let .conversationItemDeleted(event):
				entries.removeAll { $0.id == event.itemId }
			case let .conversationItemInputAudioTranscriptionCompleted(event):
				updateEvent(id: event.itemId) { message in
					guard case let .input_audio(audio) = message.content[event.contentIndex] else { return }

					message.content[event.contentIndex] = .input_audio(.init(audio: audio.audio, transcript: event.transcript))
				}
			case let .conversationItemInputAudioTranscriptionFailed(event):
				errorStream.yield(event.error)
			case let .responseContentPartAdded(event):
				updateEvent(id: event.itemId) { message in
					message.content.insert(.init(from: event.part), at: event.contentIndex)
				}
			case let .responseContentPartDone(event):
				updateEvent(id: event.itemId) { message in
					message.content[event.contentIndex] = .init(from: event.part)
				}
			case let .responseTextDelta(event):
				updateEvent(id: event.itemId) { message in
					guard case let .text(text) = message.content[event.contentIndex] else { return }

					message.content[event.contentIndex] = .text(text + event.delta)
				}
			case let .responseTextDone(event):
				updateEvent(id: event.itemId) { message in
					message.content[event.contentIndex] = .text(event.text)
				}
			case let .responseAudioTranscriptDelta(event):
				updateEvent(id: event.itemId) { message in
					guard case let .audio(audio) = message.content[event.contentIndex] else { return }

					message.content[event.contentIndex] = .audio(.init(audio: audio.audio, transcript: (audio.transcript ?? "") + event.delta))
				}
			case let .responseAudioTranscriptDone(event):
				updateEvent(id: event.itemId) { message in
					guard case let .audio(audio) = message.content[event.contentIndex] else { return }

					message.content[event.contentIndex] = .audio(.init(audio: audio.audio, transcript: event.transcript))
				}
			case let .responseAudioDelta(event):
				updateEvent(id: event.itemId) { message in
					guard case let .audio(audio) = message.content[event.contentIndex] else { return }

                    if handlingVoice { audioHandler.queueAudioSample(event) }
					message.content[event.contentIndex] = .audio(.init(audio: audio.audio + event.delta, transcript: audio.transcript))
				}
			case let .responseFunctionCallArgumentsDelta(event):
				updateEvent(id: event.itemId) { functionCall in
					functionCall.arguments.append(event.delta)
				}
			case let .responseFunctionCallArgumentsDone(event):
				updateEvent(id: event.itemId) { functionCall in
					functionCall.arguments = event.arguments
				}
			case .inputAudioBufferSpeechStarted:
				isUserSpeaking = true
				if handlingVoice { interruptSpeech() }
			case .inputAudioBufferSpeechStopped:
				isUserSpeaking = false
			case let .responseOutputItemDone(event):
				updateEvent(id: event.item.id) { message in
					guard case let .message(newMessage) = event.item else { return }

					message = newMessage
				}
			default:
				return
		}
	}

	@MainActor
	func updateEvent(id: String, modifying closure: (inout Item.Message) -> Void) {
		guard let index = entries.firstIndex(where: { $0.id == id }), case var .message(message) = entries[index] else {
			return
		}

		closure(&message)

		entries[index] = .message(message)
	}

	@MainActor
	func updateEvent(id: String, modifying closure: (inout Item.FunctionCall) -> Void) {
		guard let index = entries.firstIndex(where: { $0.id == id }), case var .functionCall(functionCall) = entries[index] else {
			return
		}

		closure(&functionCall)

		entries[index] = .functionCall(functionCall)
	}
}
