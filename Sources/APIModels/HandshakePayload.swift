import Foundation

public struct HandshakePayload: Codable, Equatable, Sendable {
    public let clientName: String
    public let clientVersion: String

    public init(clientName: String, clientVersion: String) {
        self.clientName = clientName
        self.clientVersion = clientVersion
    }
}
