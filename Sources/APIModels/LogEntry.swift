// File: LogEntry.swift
// Module: APIModels
// Description: DTO representing a single log entry for transport/discovery events.

import Foundation

public struct LogEntry: Sendable, Codable, Equatable, Identifiable {
    public let id: UUID
    public let message: String
    public let level: String?
    public let timestamp: Date?

    public init(
        id: UUID = UUID(),
        message: String,
        level: String? = nil,
        timestamp: Date? = Date()
    ) {
        self.id = id
        self.message = message
        self.level = level
        self.timestamp = timestamp
    }
}
