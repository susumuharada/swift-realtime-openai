import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import OSLog

public final class WebSocketConnector: Connector, Sendable {
	@MainActor public private(set) var onDisconnect: (@Sendable () -> Void)? = nil
	public let events: AsyncThrowingStream<ServerEvent, Error>

	private let task: Task<Void, Never>
	private let webSocket: URLSessionWebSocketTask
	private let stream: AsyncThrowingStream<ServerEvent, Error>.Continuation

	private let encoder: JSONEncoder = {
		let encoder = JSONEncoder()
		encoder.keyEncodingStrategy = .convertToSnakeCase
		return encoder
	}()

	public init(connectingTo request: URLRequest) {
		let (events, stream) = AsyncThrowingStream.makeStream(of: ServerEvent.self)

		let webSocket = URLSession.shared.webSocketTask(with: request)
        Logger.webSocketConnector.log("Resuming webSocket task with request \(request)")
		webSocket.resume()
        Logger.webSocketConnector.log("Resumed webSocket task")

		task = Task.detached { [webSocket, stream] in
			var isActive = true

			let decoder = JSONDecoder()
			decoder.keyDecodingStrategy = .convertFromSnakeCase

			while isActive, webSocket.closeCode == .invalid, !Task.isCancelled {
				guard webSocket.closeCode == .invalid else {
                    Logger.webSocketConnector.log("WebSocket closeCode was \(webSocket.closeCode.rawValue), finishing")
					stream.finish()
					isActive = false
					break
				}

				do {
                    Logger.webSocketConnector.log("Waiting to receive on web socket")
					let message = try await webSocket.receive()

					guard case let .string(text) = message, let data = text.data(using: .utf8) else {
						stream.yield(error: RealtimeAPIError.invalidMessage)
						continue
					}
                    if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
                       let jsonData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]) {
                        Logger.webSocketConnector.log("Received message on web socket:\n\(String(decoding: jsonData, as: UTF8.self))")
                    } else {
                        Logger.webSocketConnector.log("Received message on web socket:\n\(text)")
                    }

					try stream.yield(decoder.decode(ServerEvent.self, from: data))
				} catch {
                    Logger.webSocketConnector.error("ERROR: \(error)")
					stream.yield(error: error)
					isActive = false
				}
			}

            Logger.webSocketConnector.log("Cancelling web socket")
			webSocket.cancel(with: .goingAway, reason: nil)
		}

		self.events = events
		self.stream = stream
		self.webSocket = webSocket
	}

	deinit {
		webSocket.cancel(with: .goingAway, reason: nil)
		task.cancel()
		stream.finish()
		onDisconnect?()
	}

	public func send(event: ClientEvent) async throws {
        let messageString = try String(data: encoder.encode(event), encoding: .utf8)!
		let message = URLSessionWebSocketTask.Message.string(messageString)
		try await webSocket.send(message)
	}

	@MainActor public func onDisconnect(_ action: (@Sendable () -> Void)?) {
		onDisconnect = action
	}
}
