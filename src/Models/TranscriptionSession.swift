public struct TranscriptionSession: Codable, Equatable, Sendable {
	public enum Modality: String, Codable, Sendable {
		case text
		case audio
	}

	public enum AudioFormat: String, Codable, Sendable {
		case pcm16
		case g711_ulaw
		case g711_alaw
	}

	public struct InputAudioTranscription: Codable, Equatable, Sendable {
		public enum TranscriptionModel: String, CaseIterable, Codable, Sendable {
			case whisper = "whisper-1"
			case gpt4o = "gpt-4o-transcribe"
			case gpt4oMini = "gpt-4o-mini-transcribe"
		}

		/// The model to use for transcription
		public var model: TranscriptionModel
		/// The language of the input audio. Supplying the input language in ISO-639-1 (e.g. `en`) format will improve accuracy and latency.
		public var language: String?
		/// An optional text to guide the model's style or continue a previous audio segment.
		///
		/// For `whisper`, the [prompt is a list of keywords](https://platform.openai.com/docs/guides/speech-to-text#prompting). For `gpt4o` models, the prompt is a free text string, for example "expect words related to technology".
		public var prompt: String?

		public init(model: TranscriptionModel = .gpt4o,
                    language: String? = nil,
                    prompt: String? = nil) {
			self.model = model
            self.language = language
            self.prompt = prompt
		}
	}

	public struct TurnDetection: Codable, Equatable, Sendable {
		public enum TurnDetectionType: String, Codable, Sendable {
			case serverVad = "server_vad"
			case semanticVad = "semantic_vad"
			case none
		}

		public enum TurnDetectionEagerness: String, Codable, Sendable {
			case low
			case high
			case auto
			case medium
		}

		/// The type of turn detection.
		public var type: TurnDetectionType
		/// Used only for `server_vad` mode. Activation threshold for VAD (0.0 to 1.0).
		public var threshold: Double?
		/// Whether or not to automatically interrupt any ongoing response with output to the default conversation (i.e. `conversation` of `auto`) when a VAD start event occurs.
		public var interruptResponse: Bool?
		/// Used only for `server_vad` mode. Amount of audio to include before speech starts (in milliseconds).
		public var prefixPaddingMs: Int?
		/// Used only for `server_vad` mode. Duration of silence to detect speech stop (in milliseconds).
		public var silenceDurationMs: Int?
		/// Used only for `semantic_vad` mode. The eagerness of the model to respond. `low` will wait longer for the user to continue speaking, `high` will respond more quickly. `auto` is the default and is equivalent to `medium`.
		public var eagerness: TurnDetectionEagerness?

		public init(type: TurnDetectionType = .serverVad, threshold: Double? = nil, interruptResponse: Bool? = nil, prefixPaddingMs: Int? = nil, silenceDurationMs: Int? = nil, eagerness: TurnDetectionEagerness? = nil) {
			self.type = type
			self.eagerness = eagerness
			self.threshold = threshold
			self.prefixPaddingMs = prefixPaddingMs
			self.silenceDurationMs = silenceDurationMs
			self.interruptResponse = interruptResponse
		}

		public static func serverVad(threshold: Double? = nil, interruptResponse: Bool? = nil, prefixPaddingMs: Int? = nil, silenceDurationMs: Int? = nil) -> TurnDetection {
			.init(type: .serverVad, threshold: threshold, interruptResponse: interruptResponse, prefixPaddingMs: prefixPaddingMs, silenceDurationMs: silenceDurationMs)
		}

		public static func semanticVad(eagerness: TurnDetectionEagerness = .auto) -> TurnDetection {
			.init(type: .semanticVad, eagerness: eagerness)
		}
	}

	/// The unique ID of the session.
	public var id: String?
	/// The set of modalities the model can respond with.
	public var modalities: [Modality]?
	/// The format of input audio.
	public var inputAudioFormat: AudioFormat
	/// Configuration for input audio transcription.
	public var inputAudioTranscription: InputAudioTranscription?
	/// Configuration for turn detection.
	public var turnDetection: TurnDetection?

	public init(
		id: String? = nil,
        modalities: [Modality] = [.text],
        inputAudioFormat: AudioFormat = .pcm16,
        inputAudioTranscription: InputAudioTranscription? = nil,
        turnDetection: TurnDetection? = nil
	) {
		self.id = id
        self.modalities = modalities
        self.inputAudioFormat = inputAudioFormat
        self.inputAudioTranscription = inputAudioTranscription
        self.turnDetection = turnDetection
	}
}
