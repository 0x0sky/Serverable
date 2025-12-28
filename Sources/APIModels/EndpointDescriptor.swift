import Foundation

public struct EndpointDescriptor: Sendable, Hashable {
    public let displayName: String
    public let host: String?
    public let port: Int?

    public init(displayName: String, host: String? = nil, port: Int? = nil) {
        self.displayName = displayName
        self.host = host
        self.port = port
    }
}
