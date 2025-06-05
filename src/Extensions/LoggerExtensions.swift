//
//  LoggerExtensions.swift
//  OpenAIRealtime
//
//  Created by Susumu Harada on 6/4/25.
//

import Foundation
import OSLog

extension Logger {
    static let subsystem = Bundle.main.bundleIdentifier ?? "OpenAIRealtime"

    static let audioHandler = Logger(subsystem: subsystem, category: "AudioHandler")
    static let avAudioPCMBufferExtension = Logger(subsystem: subsystem, category: "AVAudioPCMBufferExtension")
    static let conversation = Logger(subsystem: subsystem, category: "Conversation")
    static let realtimeAPI = Logger(subsystem: subsystem, category: "RealtimeAPI")
    static let transcription = Logger(subsystem: subsystem, category: "Transcription")
    static let webSocketConnector = Logger(subsystem: subsystem, category: "WebSocketConnector")
}
