// File: CoreNetworkingProtocols.swift
// Module: CoreNetworking
// Description: Core networking protocols and lightweight DTOs.

import Foundation

// MARK: - BonjourEndpoint

public struct BonjourEndpoint: Sendable, Equatable, Hashable {
    public let host: String
    public let port: Int

    public init(host: String, port: Int) {
        self.host = host
        self.port = port
    }
}

// MARK: - TransportEvent

public enum TransportEvent: Sendable, Equatable {
    case connected
    case disconnected
    case messageReceived(Data)
    case error(String)
}

// MARK: - DiscoveryService

public protocol DiscoveryService: AnyObject {
    func start() async
    func stop() async
    func events() async -> AsyncStream<BonjourEndpoint>
}

// MARK: - TransportService

public protocol TransportService: AnyObject {
    func connect(to endpoint: BonjourEndpoint) async throws
    func disconnect() async throws
    func send(_ data: Data) async throws
    func events() async -> AsyncStream<TransportEvent>?
}
