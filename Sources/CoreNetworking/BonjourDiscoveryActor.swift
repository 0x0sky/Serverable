// File: BonjourDiscoveryActor.swift
// Module: Serverable
// Description: Actor implementing DiscoveryService. Emits discovered BonjourEndpoint via AsyncStream.

import Foundation
import CoreNetworking

public actor BonjourDiscoveryActor: DiscoveryService {
    private var continuation: AsyncStream<BonjourEndpoint>.Continuation?
    private var isRunning: Bool = false
    private var simulationTask: Task<Void, Never>?

    public init() {}

    public func start() async {
        guard !isRunning else { return }
        isRunning = true
        if continuation == nil { _ = await events() }

        simulationTask = Task.detached { [weak self] in
            guard let self = self else { return }
            var counter = 1
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                let ep = BonjourEndpoint(host: "192.168.1.\(100 + (counter % 50))", port: 8000 + (counter % 100))
                await self.yield(endpoint: ep)
                counter += 1
            }
        }
    }

    public func stop() async {
        guard isRunning else { return }
        isRunning = false
        simulationTask?.cancel()
        simulationTask = nil
        continuation?.finish()
        continuation = nil
    }

    public func events() async -> AsyncStream<BonjourEndpoint> {
        if let _ = continuation {
            return AsyncStream { cont in cont.onTermination = { _ in } }
        }
        let stream = AsyncStream<BonjourEndpoint> { cont in
            self.continuation = cont
            cont.onTermination = { @Sendable _ in Task { await self.stop() } }
        }
        return stream
    }

    private func yield(endpoint: BonjourEndpoint) async {
        continuation?.yield(endpoint)
    }
}
