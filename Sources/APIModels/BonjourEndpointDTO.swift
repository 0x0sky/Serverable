// File: BonjourEndpointDTO.swift
// Module: APIModels
// Description: DTO for Bonjour endpoint representation in API layer.

import Foundation

public struct BonjourEndpointDTO: Sendable, Codable, Equatable, Hashable {
    public let host: String
    public let port: Int

    public init(host: String, port: Int) {
        self.host = host
        self.port = port
    }
}
