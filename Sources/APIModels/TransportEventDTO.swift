// File: TransportEventDTO.swift
// Module: APIModels
// Description: DTO for transport events in API layer.

import Foundation

public enum TransportEventDTO: Sendable, Codable, Equatable {
    case connected
    case disconnected
    case messageReceived(Data)
    case error(String)

    // Codable support for enum with associated values
    private enum CodingKeys: String, CodingKey {
        case type, data, message
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "connected": self = .connected
        case "disconnected": self = .disconnected
        case "messageReceived":
            let data = try container.decode(Data.self, forKey: .data)
            self = .messageReceived(data)
        case "error":
            let msg = try container.decode(String.self, forKey: .message)
            self = .error(msg)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .connected:
            try container.encode("connected", forKey: .type)
        case .disconnected:
            try container.encode("disconnected", forKey: .type)
        case .messageReceived(let data):
            try container.encode("messageReceived", forKey: .type)
            try container.encode(data, forKey: .data)
        case .error(let msg):
            try container.encode("error", forKey: .type)
            try container.encode(msg, forKey: .message)
        }
    }
}
