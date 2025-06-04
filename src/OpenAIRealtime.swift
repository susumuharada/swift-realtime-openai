import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

enum RealtimeAPIError: Error {
	case invalidMessage
}

public final class RealtimeAPI: NSObject, Sendable {
	@MainActor public var onDisconnect: (@Sendable () -> Void)? {
		get { connector.onDisconnect }
		set { connector.onDisconnect(newValue) }
	}

	public var events: AsyncThrowingStream<ServerEvent, Error> {
		connector.events
	}

	let connector: any Connector

	/// Connect to the OpenAI Realtime API using the given connector instance.
	public init(connector: any Connector) {
		self.connector = connector

		super.init()
	}

	public func send(event: ClientEvent) async throws {
		try await connector.send(event: event)
	}
}

/// Helper methods for connecting to the OpenAI Realtime API.
extension RealtimeAPI {
	/// Connect to the OpenAI WebSocket Realtime API with the given request.
	static func webSocket(connectingTo request: URLRequest) -> RealtimeAPI {
		RealtimeAPI(connector: WebSocketConnector(connectingTo: request))
	}

	/// Connect to the OpenAI WebSocket Realtime API with the given authentication token and model.
    static func webSocket(authToken: String, forTranscription: Bool = false, model: String = "gpt-4o-realtime-preview") -> RealtimeAPI {
        var requestURL = URL(string: "wss://api.openai.com/v1/realtime")!
        if forTranscription {
            requestURL.append(queryItems: [URLQueryItem(name: "intent", value: "transcription")])
        } else {
            requestURL.append(queryItems: [URLQueryItem(name: "model", value: model)])
        }
        print("Request URL: \(requestURL.absoluteString)")
        var request = URLRequest(url: requestURL)
		request.addValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")
		request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

		return webSocket(connectingTo: request)
	}
}
