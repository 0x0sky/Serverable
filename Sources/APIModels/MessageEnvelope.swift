import Foundation

public enum MessageType: String, Codable, Sendable {
    case handshake
    case data
    case error
    case ping
    case pong
}

public struct MessageEnvelope<T: Codable & Sendable>: Codable, Sendable {
    public let type: MessageType
    public let payload: T

    public init(type: MessageType, payload: T) {
        self.type = type
        self.payload = payload
    }
}

extension MessageEnvelope: Equatable where T: Equatable {}
