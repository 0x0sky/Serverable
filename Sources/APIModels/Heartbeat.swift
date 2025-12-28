import Foundation

public struct HeartbeatConfig: Sendable {
    public let interval: TimeInterval
    public let serverTimeout: TimeInterval

    public init(interval: TimeInterval = 10, serverTimeout: TimeInterval = 30) {
        self.interval = interval
        self.serverTimeout = serverTimeout
    }
}

public enum HeartbeatPayload: Codable, Sendable, Equatable {
    case ping(timestamp: TimeInterval)
    case pong(timestamp: TimeInterval)
}
