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

    static let audio = Logger(subsystem: subsystem, category: "Audio")
}
