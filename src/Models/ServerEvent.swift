import Foundation

public enum ServerEvent: Sendable {
	public struct ErrorEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// Details of the error.
		public let error: ServerError
	}

	public struct SessionEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The session resource.
		public let session: Session
	}

    public struct TranscriptionSessionEvent: Codable, Sendable {
        /// The unique ID of the server event.
        public let eventId: String
        /// The session resource.
        public let session: TranscriptionSession
    }

	public struct ConversationCreatedEvent: Codable, Sendable {
		public struct Conversation: Codable, Sendable {
			/// The unique ID of the conversation.
			public let id: String
		}

		/// The unique ID of the server event.
		public let eventId: String
		/// The conversation resource.
		public let conversation: Conversation
	}

	public struct InputAudioBufferCommittedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the preceding item after which the new item will be inserted.
		public let previousItemId: String?
		/// The ID of the user message item that will be created.
		public let itemId: String
	}

	public struct InputAudioBufferClearedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
	}

	public struct InputAudioBufferSpeechStartedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// Milliseconds since the session started when speech was detected.
		public let audioStartMs: Int
		/// The ID of the user message item that will be created when speech stops.
		public let itemId: String
	}

	public struct InputAudioBufferSpeechStoppedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// Milliseconds since the session started when speech stopped.
		public let audioEndMs: Int
		/// The ID of the user message item that will be created.
		public let itemId: String
	}

	public struct ConversationItemCreatedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the preceding item.
		public let previousItemId: String?
		/// The item that was created.
		public let item: Item
	}

	public struct ConversationItemInputAudioTranscriptionCompletedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the user message item.
		public let itemId: String
		/// The index of the content part containing the audio.
		public let contentIndex: Int
		/// The transcribed text.
		public let transcript: String
	}

	public struct ConversationItemInputAudioTranscriptionDeltaEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the user message item.
		public let itemId: String
		/// The index of the content part containing the audio.
		public let contentIndex: Int
		/// The transcribed delta text.
		public let delta: String
	}

	public struct ConversationItemInputAudioTranscriptionFailedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the user message item.
		public let itemId: String
		/// The index of the content part containing the audio.
		public let contentIndex: Int
		/// Details of the transcription error.
		public let error: ServerError
	}

	public struct ConversationItemTruncatedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the assistant message item that was truncated.
		public let itemId: String
		/// The index of the content part that was truncated.
		public let contentIndex: Int
		/// The duration up to which the audio was truncated, in milliseconds.
		public let audioEndMs: Int
	}

	public struct ConversationItemDeletedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the item that was deleted.
		public let itemId: String
	}

	public struct OutputAudioBufferStartedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
	}

	public struct OutputAudioBufferStoppedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
	}

	public struct ResponseEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The response resource.
		public let response: Response
	}

	public struct ResponseOutputItemAddedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response to which the item belongs.
		public let responseId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The item that was added.
		public let item: Item
	}

	public struct ResponseOutputItemDoneEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response to which the item belongs.
		public let responseId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The completed item.
		public let item: Item
	}

	public struct ResponseContentPartAddedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
		/// The ID of the item to which the content part was added.
		public let itemId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The index of the content part in the item's content array.
		public let contentIndex: Int
		/// The content part that was added.
		public let part: Item.ContentPart
	}

	public struct ResponseContentPartDoneEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
		/// The ID of the item.
		public let itemId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The index of the content part in the item's content array.
		public let contentIndex: Int
		/// The content part that is done.
		public let part: Item.ContentPart
	}

	public struct ResponseTextDeltaEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
		/// The ID of the item.
		public let itemId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The index of the content part in the item's content array.
		public let contentIndex: Int
		/// The text delta.
		public let delta: String
	}

	public struct ResponseTextDoneEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
		/// The ID of the item.
		public let itemId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The index of the content part in the item's content array.
		public let contentIndex: Int
		/// The final text content.
		public let text: String
	}

	public struct ResponseAudioTranscriptDeltaEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
		/// The ID of the item.
		public let itemId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The index of the content part in the item's content array.
		public let contentIndex: Int
		/// The transcript delta.
		public let delta: String
	}

	public struct ResponseAudioTranscriptDoneEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
		/// The ID of the item.
		public let itemId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The index of the content part in the item's content array.
		public let contentIndex: Int
		/// The final transcript of the audio.
		public let transcript: String
	}

	public struct ResponseAudioDeltaEvent: Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
		/// The ID of the item.
		public let itemId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The index of the content part in the item's content array.
		public let contentIndex: Int
		/// Base64-encoded audio data delta.
		public let delta: Data
	}

	public struct ResponseAudioDoneEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
		/// The ID of the item.
		public let itemId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The index of the content part in the item's content array.
		public let contentIndex: Int
	}

	public struct ResponseFunctionCallArgumentsDeltaEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
		/// The ID of the function call item.
		public let itemId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The ID of the function call.
		public let callId: String
		/// The arguments delta as a JSON string.
		public let delta: String
	}

	public struct ResponseFunctionCallArgumentsDoneEvent: Codable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
		/// The ID of the function call item.
		public let itemId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The ID of the function call.
		public let callId: String
		/// The final arguments as a JSON string.
		public let arguments: String
	}

	public struct RateLimitsUpdatedEvent: Codable, Sendable {
		public struct RateLimit: Codable, Sendable {
			/// The name of the rate limit
			public let name: String
			/// The maximum allowed value for the rate limit.
			public let limit: Int
			/// The remaining value before the limit is reached.
			public let remaining: Int
			/// Seconds until the rate limit resets.
			public let resetSeconds: Double
		}

		/// The unique ID of the server event.
		public let eventId: String
		/// List of rate limit information.
		public let rateLimits: [RateLimit]
	}

	/// Returned when an error occurs.
	case error(ErrorEvent)
	/// Returned when a session is created. Emitted automatically when a new connection is established.
	case sessionCreated(SessionEvent)
    /// Returned when a transcription session is created. Emitted automatically when a new connection is established.
    case transcriptionSessionCreated(TranscriptionSessionEvent)
	/// Returned when a session is updated.
	case sessionUpdated(SessionEvent)
    /// Returned when a transcription session is updated.
    case transcriptionSessionUpdated(TranscriptionSessionEvent)
	/// Returned when a conversation is created. Emitted right after session creation.
	case conversationCreated(ConversationCreatedEvent)
	/// Returned when an input audio buffer is committed, either by the client or automatically in server VAD mode.
	case inputAudioBufferCommitted(InputAudioBufferCommittedEvent)
	/// Returned when the input audio buffer is cleared by the client.
	case inputAudioBufferCleared(InputAudioBufferClearedEvent)
	/// Returned in server turn detection mode when speech is detected.
	case inputAudioBufferSpeechStarted(InputAudioBufferSpeechStartedEvent)
	/// Returned in server turn detection mode when speech stops.
	case inputAudioBufferSpeechStopped(InputAudioBufferSpeechStoppedEvent)
	/// Returned when a conversation item is created.
	case conversationItemCreated(ConversationItemCreatedEvent)
	/// Returned when input audio transcription is enabled and a transcription succeeds.
	case conversationItemInputAudioTranscriptionCompleted(ConversationItemInputAudioTranscriptionCompletedEvent)
	/// Returned when input audio transcription is enabled and a transcription receives delta.
	case conversationItemInputAudioTranscriptionDelta(ConversationItemInputAudioTranscriptionDeltaEvent)
	/// Returned when input audio transcription is configured, and a transcription request for a user message failed.
	case conversationItemInputAudioTranscriptionFailed(ConversationItemInputAudioTranscriptionFailedEvent)
	/// Returned when an earlier assistant audio message item is truncated by the client.
	case conversationItemTruncated(ConversationItemTruncatedEvent)
	/// Returned when an item in the conversation is deleted.
	case conversationItemDeleted(ConversationItemDeletedEvent)
	/// Returned when the output audio buffer is started.
	case outputAudioBufferStarted(OutputAudioBufferStartedEvent)
	/// Returned when the output audio buffer is stopped.
	case outputAudioBufferStopped(OutputAudioBufferStoppedEvent)
	/// Returned when a new Response is created. The first event of response creation, where the response is in an initial state of "in_progress".
	case responseCreated(ResponseEvent)
	/// Returned when a Response is done streaming. Always emitted, no matter the final state.
	case responseDone(ResponseEvent)
	/// Returned when a new Item is created during response generation.
	case responseOutputItemAdded(ResponseOutputItemAddedEvent)
	/// Returned when an Item is done streaming. Also emitted when a Response is interrupted, incomplete, or cancelled.
	case responseOutputItemDone(ResponseOutputItemDoneEvent)
	/// Returned when a new content part is added to an assistant message item during response generation.
	case responseContentPartAdded(ResponseContentPartAddedEvent)
	/// Returned when a content part is done streaming in an assistant message item. Also emitted when a Response is interrupted, incomplete, or cancelled.
	case responseContentPartDone(ResponseContentPartDoneEvent)
	/// Returned when the text value of a "text" content part is updated.
	case responseTextDelta(ResponseTextDeltaEvent)
	/// Returned when the text value of a "text" content part is done streaming. Also emitted when a Response is interrupted, incomplete, or cancelled.
	case responseTextDone(ResponseTextDoneEvent)
	/// Returned when the model-generated transcription of audio output is updated.
	case responseAudioTranscriptDelta(ResponseAudioTranscriptDeltaEvent)
	/// Returned when the model-generated transcription of audio output is done streaming. Also emitted when a Response is interrupted, incomplete, or cancelled.
	case responseAudioTranscriptDone(ResponseAudioTranscriptDoneEvent)
	/// Returned when the model-generated audio is updated.
	case responseAudioDelta(ResponseAudioDeltaEvent)
	/// Returned when the model-generated audio is done. Also emitted when a Response is interrupted, incomplete, or cancelled.
	case responseAudioDone(ResponseAudioDoneEvent)
	/// Returned when the model-generated function call arguments are updated.
	case responseFunctionCallArgumentsDelta(ResponseFunctionCallArgumentsDeltaEvent)
	/// Returned when the model-generated function call arguments are done streaming. Also emitted when a Response is interrupted, incomplete, or cancelled.
	case responseFunctionCallArgumentsDone(ResponseFunctionCallArgumentsDoneEvent)
	/// Emitted after every "response.done" event to indicate the updated rate limits.
	case rateLimitsUpdated(RateLimitsUpdatedEvent)
}

enum ServerEventType: String {
    case error = "error"
    case sessionCreated = "session.created"
    case transcriptionSessionCreated = "transcription_session.created"
    case sessionUpdated = "session.updated"
    case transcriptionSessionUpdated = "transcription_session.updated"
    case conversationCreated = "conversation.created"
    case inputAudioBufferCommitted = "input_audio_buffer.committed"
    case inputAudioBufferCleared = "input_audio_buffer.cleared"
    case inputAudioBufferSpeechStarted = "input_audio_buffer.speech_started"
    case inputAudioBufferSpeechStopped = "input_audio_buffer.speech_stopped"
    case conversationItemCreated = "conversation.item.created"
    case conversationItemInputAudioTranscriptionCompleted = "conversation.item.input_audio_transcription.completed"
    case conversationItemInputAudioTranscriptionDelta = "conversation.item.input_audio_transcription.delta"
    case conversationItemInputAudioTranscriptionFailed = "conversation.item.input_audio_transcription.failed"
    case conversationItemTruncated = "conversation.item.truncated"
    case conversationItemDeleted = "conversation.item.deleted"
    case outputAudioBufferStarted = "output_audio_buffer.started"
    case outputAudioBufferStopped = "output_audio_buffer.stopped"
    case responseCreated = "response.created"
    case responseDone = "response.done"
    case responseOutputItemAdded = "response.output_item.added"
    case responseOutputItemDone = "response.output_item.done"
    case responseContentPartAdded = "response.content_part.added"
    case responseContentPartDone = "response.content_part.done"
    case responseTextDelta = "response.text.delta"
    case responseTextDone = "response.text.done"
    case responseAudioTranscriptDelta = "response.audio_transcript.delta"
    case responseAudioTranscriptDone = "response.audio_transcript.done"
    case responseAudioDelta = "response.audio.delta"
    case responseAudioDone = "response.audio.done"
    case responseFunctionCallArgumentsDelta = "response.function_call_arguments.delta"
    case responseFunctionCallArgumentsDone = "response.function_call_arguments.done"
    case rateLimitsUpdated = "rate_limits.updated"
}

extension ServerEvent: Identifiable {
	public var id: String {
		switch self {
			case let .error(event):
				return event.eventId
			case let .sessionCreated(event):
				return event.eventId
            case let .transcriptionSessionCreated(event):
                return event.eventId
			case let .sessionUpdated(event):
				return event.eventId
            case let .transcriptionSessionUpdated(event):
                return event.eventId
			case let .conversationCreated(event):
				return event.eventId
			case let .inputAudioBufferCommitted(event):
				return event.eventId
			case let .inputAudioBufferCleared(event):
				return event.eventId
			case let .inputAudioBufferSpeechStarted(event):
				return event.eventId
			case let .inputAudioBufferSpeechStopped(event):
				return event.eventId
			case let .conversationItemCreated(event):
				return event.eventId
			case let .conversationItemInputAudioTranscriptionCompleted(event):
				return event.eventId
			case let .conversationItemInputAudioTranscriptionDelta(event):
				return event.eventId
			case let .conversationItemInputAudioTranscriptionFailed(event):
				return event.eventId
			case let .conversationItemTruncated(event):
				return event.eventId
			case let .conversationItemDeleted(event):
				return event.eventId
			case let .outputAudioBufferStarted(event):
				return event.eventId
			case let .outputAudioBufferStopped(event):
				return event.eventId
			case let .responseCreated(event):
				return event.eventId
			case let .responseDone(event):
				return event.eventId
			case let .responseOutputItemAdded(event):
				return event.eventId
			case let .responseOutputItemDone(event):
				return event.eventId
			case let .responseContentPartAdded(event):
				return event.eventId
			case let .responseContentPartDone(event):
				return event.eventId
			case let .responseTextDelta(event):
				return event.eventId
			case let .responseTextDone(event):
				return event.eventId
			case let .responseAudioTranscriptDelta(event):
				return event.eventId
			case let .responseAudioTranscriptDone(event):
				return event.eventId
			case let .responseAudioDelta(event):
				return event.eventId
			case let .responseAudioDone(event):
				return event.eventId
			case let .responseFunctionCallArgumentsDelta(event):
				return event.eventId
			case let .responseFunctionCallArgumentsDone(event):
				return event.eventId
			case let .rateLimitsUpdated(event):
				return event.eventId
		}
	}
}

extension ServerEvent: Codable {
	private enum CodingKeys: String, CodingKey {
		case type
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let eventTypeString = try container.decode(String.self, forKey: .type)
        let eventType = ServerEventType(rawValue: eventTypeString)

		switch eventType {
            case .error:
				self = try .error(ErrorEvent(from: decoder))
            case .sessionCreated:
				self = try .sessionCreated(SessionEvent(from: decoder))
            case .transcriptionSessionCreated:
                self = try .transcriptionSessionCreated(TranscriptionSessionEvent(from: decoder))
            case .sessionUpdated:
				self = try .sessionUpdated(SessionEvent(from: decoder))
            case .transcriptionSessionUpdated:
                self = try .transcriptionSessionUpdated(TranscriptionSessionEvent(from: decoder))
			case .conversationCreated:
				self = try .conversationCreated(ConversationCreatedEvent(from: decoder))
			case .inputAudioBufferCommitted:
				self = try .inputAudioBufferCommitted(InputAudioBufferCommittedEvent(from: decoder))
			case .inputAudioBufferCleared:
				self = try .inputAudioBufferCleared(InputAudioBufferClearedEvent(from: decoder))
			case .inputAudioBufferSpeechStarted:
				self = try .inputAudioBufferSpeechStarted(InputAudioBufferSpeechStartedEvent(from: decoder))
			case .inputAudioBufferSpeechStopped:
				self = try .inputAudioBufferSpeechStopped(InputAudioBufferSpeechStoppedEvent(from: decoder))
			case .conversationItemCreated:
				self = try .conversationItemCreated(ConversationItemCreatedEvent(from: decoder))
			case .conversationItemInputAudioTranscriptionCompleted:
				self = try .conversationItemInputAudioTranscriptionCompleted(ConversationItemInputAudioTranscriptionCompletedEvent(from: decoder))
			case .conversationItemInputAudioTranscriptionDelta:
				self = try .conversationItemInputAudioTranscriptionDelta(ConversationItemInputAudioTranscriptionDeltaEvent(from: decoder))
			case .conversationItemInputAudioTranscriptionFailed:
				self = try .conversationItemInputAudioTranscriptionFailed(ConversationItemInputAudioTranscriptionFailedEvent(from: decoder))
			case .conversationItemTruncated:
				self = try .conversationItemTruncated(ConversationItemTruncatedEvent(from: decoder))
			case .conversationItemDeleted:
				self = try .conversationItemDeleted(ConversationItemDeletedEvent(from: decoder))
			case .outputAudioBufferStarted:
				self = try .outputAudioBufferStarted(OutputAudioBufferStartedEvent(from: decoder))
			case .outputAudioBufferStopped:
				self = try .outputAudioBufferStopped(OutputAudioBufferStoppedEvent(from: decoder))
			case .responseCreated:
				self = try .responseCreated(ResponseEvent(from: decoder))
			case .responseDone:
				self = try .responseDone(ResponseEvent(from: decoder))
			case .responseOutputItemAdded:
				self = try .responseOutputItemAdded(ResponseOutputItemAddedEvent(from: decoder))
			case .responseOutputItemDone:
				self = try .responseOutputItemDone(ResponseOutputItemDoneEvent(from: decoder))
			case .responseContentPartAdded:
				self = try .responseContentPartAdded(ResponseContentPartAddedEvent(from: decoder))
			case .responseContentPartDone:
				self = try .responseContentPartDone(ResponseContentPartDoneEvent(from: decoder))
			case .responseTextDelta:
				self = try .responseTextDelta(ResponseTextDeltaEvent(from: decoder))
			case .responseTextDone:
				self = try .responseTextDone(ResponseTextDoneEvent(from: decoder))
			case .responseAudioTranscriptDelta:
				self = try .responseAudioTranscriptDelta(ResponseAudioTranscriptDeltaEvent(from: decoder))
			case .responseAudioTranscriptDone:
				self = try .responseAudioTranscriptDone(ResponseAudioTranscriptDoneEvent(from: decoder))
			case .responseAudioDelta:
				self = try .responseAudioDelta(ResponseAudioDeltaEvent(from: decoder))
			case .responseAudioDone:
				self = try .responseAudioDone(ResponseAudioDoneEvent(from: decoder))
			case .responseFunctionCallArgumentsDelta:
				self = try .responseFunctionCallArgumentsDelta(ResponseFunctionCallArgumentsDeltaEvent(from: decoder))
			case .responseFunctionCallArgumentsDone:
				self = try .responseFunctionCallArgumentsDone(ResponseFunctionCallArgumentsDoneEvent(from: decoder))
			case .rateLimitsUpdated:
				self = try .rateLimitsUpdated(RateLimitsUpdatedEvent(from: decoder))
			case nil:
				throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown event type: \(eventTypeString)")
			}
	}

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .error(let event):
            try container.encode(ServerEventType.error.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .sessionCreated(let event):
            try container.encode(ServerEventType.sessionCreated.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .transcriptionSessionCreated(let event):
            try container.encode(ServerEventType.transcriptionSessionCreated.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .sessionUpdated(let event):
            try container.encode(ServerEventType.sessionUpdated.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .transcriptionSessionUpdated(let event):
            try container.encode(ServerEventType.transcriptionSessionUpdated.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .conversationCreated(let event):
            try container.encode(ServerEventType.conversationCreated.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .inputAudioBufferCommitted(let event):
            try container.encode(ServerEventType.inputAudioBufferCommitted.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .inputAudioBufferCleared(let event):
            try container.encode(ServerEventType.inputAudioBufferCleared.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .inputAudioBufferSpeechStarted(let event):
            try container.encode(ServerEventType.inputAudioBufferSpeechStarted.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .inputAudioBufferSpeechStopped(let event):
            try container.encode(ServerEventType.inputAudioBufferSpeechStopped.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .conversationItemCreated(let event):
            try container.encode(ServerEventType.conversationItemCreated.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .conversationItemInputAudioTranscriptionCompleted(let event):
            try container.encode(ServerEventType.conversationItemInputAudioTranscriptionCompleted.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .conversationItemInputAudioTranscriptionDelta(let event):
            try container.encode(ServerEventType.conversationItemInputAudioTranscriptionDelta.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .conversationItemInputAudioTranscriptionFailed(let event):
            try container.encode(ServerEventType.conversationItemInputAudioTranscriptionFailed.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .conversationItemTruncated(let event):
            try container.encode(ServerEventType.conversationItemTruncated.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .conversationItemDeleted(let event):
            try container.encode(ServerEventType.conversationItemDeleted.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .outputAudioBufferStarted(let event):
            try container.encode(ServerEventType.outputAudioBufferStarted.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .outputAudioBufferStopped(let event):
            try container.encode(ServerEventType.outputAudioBufferStopped.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .responseCreated(let event):
            try container.encode(ServerEventType.responseCreated.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .responseDone(let event):
            try container.encode(ServerEventType.responseDone.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .responseOutputItemAdded(let event):
            try container.encode(ServerEventType.responseOutputItemAdded.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .responseOutputItemDone(let event):
            try container.encode(ServerEventType.responseOutputItemDone.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .responseContentPartAdded(let event):
            try container.encode(ServerEventType.responseContentPartAdded.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .responseContentPartDone(let event):
            try container.encode(ServerEventType.responseContentPartDone.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .responseTextDelta(let event):
            try container.encode(ServerEventType.responseTextDelta.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .responseTextDone(let event):
            try container.encode(ServerEventType.responseTextDone.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .responseAudioTranscriptDelta(let event):
            try container.encode(ServerEventType.responseAudioTranscriptDelta.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .responseAudioTranscriptDone(let event):
            try container.encode(ServerEventType.responseAudioTranscriptDone.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .responseAudioDelta(let event):
            try container.encode(ServerEventType.responseAudioDelta.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .responseAudioDone(let event):
            try container.encode(ServerEventType.responseAudioDone.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .responseFunctionCallArgumentsDelta(let event):
            try container.encode(ServerEventType.responseFunctionCallArgumentsDelta.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .responseFunctionCallArgumentsDone(let event):
            try container.encode(ServerEventType.responseFunctionCallArgumentsDone.rawValue, forKey: .type)
            try event.encode(to: encoder)
        case .rateLimitsUpdated(let event):
            try container.encode(ServerEventType.rateLimitsUpdated.rawValue, forKey: .type)
            try event.encode(to: encoder)
        }
    }
}

extension ServerEvent: CustomDebugStringConvertible {
    public var debugDescription: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        do {
            let jsonData = try encoder.encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            } else {
                return "Failed to convert JSON data to string"
            }
        } catch {
            return "Failed to encode ServerEvent to JSON for debugDescription: \(error)"
        }
    }
}

extension ServerEvent.ResponseAudioDeltaEvent: Codable {
	private enum CodingKeys: CodingKey {
		case eventId
		case responseId
		case itemId
		case outputIndex
		case contentIndex
		case delta
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		itemId = try container.decode(String.self, forKey: .itemId)
		eventId = try container.decode(String.self, forKey: .eventId)
		outputIndex = try container.decode(Int.self, forKey: .outputIndex)
		responseId = try container.decode(String.self, forKey: .responseId)
		contentIndex = try container.decode(Int.self, forKey: .contentIndex)

		guard let decodedDelta = try Data(base64Encoded: container.decode(String.self, forKey: .delta)) else {
			throw DecodingError.dataCorruptedError(forKey: .delta, in: container, debugDescription: "Invalid base64-encoded audio data.")
		}
		delta = decodedDelta
	}
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventId, forKey: .eventId)
        try container.encode(responseId, forKey: .responseId)
        try container.encode(itemId, forKey: .itemId)
        try container.encode(outputIndex, forKey: .outputIndex)
        try container.encode(contentIndex, forKey: .contentIndex)
        try container.encode(delta.base64EncodedString(), forKey: .delta)
    }
}
