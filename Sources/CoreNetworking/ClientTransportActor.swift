// File: ClientTransportActor.swift
// Module: Serverable
// Description: Actor implementing TransportService. Provides connect/disconnect/send and an events stream.

import Foundation
import CoreNetworking

public enum TransportError: Error, LocalizedError {
    case notConnected
    case connectionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notConnected: return "Transport is not connected"
        case .connectionFailed(let s): return "Connection failed: \(s)"
        }
    }
}

public actor ClientTransportActor: TransportService {
    private var isConnected: Bool = false
    private var connectedEndpoint: BonjourEndpoint?
    private var eventsContinuation: AsyncStream<TransportEvent>.Continuation?
    private var receiveTask: Task<Void, Never>?

    public init() {}

    public func connect(to endpoint: BonjourEndpoint) async throws {
        guard !isConnected else { return }
        try await Task.sleep(nanoseconds: 300_000_000)
        isConnected = true
        connectedEndpoint = endpoint
        eventsContinuation?.yield(.connected)

        receiveTask = Task.detached { [weak self] in
            guard let self = self else { return }
            var counter = 0
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                let payload = "ping \(counter)".data(using: .utf8) ?? Data()
                await self.eventsContinuation?.yield(.messageReceived(payload))
                counter += 1
            }
        }
    }

    public func disconnect() async throws {
        guard isConnected else { return }
        receiveTask?.cancel()
        receiveTask = nil
        isConnected = false
        connectedEndpoint = nil
        eventsContinuation?.yield(.disconnected)
    }

    public func send(_ data: Data) async throws {
        guard isConnected else { throw TransportError.notConnected }
        try await Task.sleep(nanoseconds: 50_000_000)
        eventsContinuation?.yield(.messageReceived(data))
    }

    public func events() async -> AsyncStream<TransportEvent>? {
        if let _ = eventsContinuation {
            return AsyncStream { cont in cont.onTermination = { _ in } }
        }
        let stream = AsyncStream<TransportEvent> { cont in
            self.eventsContinuation = cont
            cont.onTermination = { @Sendable _ in Task { [weak self] in await self?.disconnectIfNeededOnTermination() } }
        }
        return stream
    }

    private func disconnectIfNeededOnTermination() async {
        if isConnected { try? await disconnect() }
        eventsContinuation = nil
    }
}
