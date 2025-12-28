import Foundation
import APIModels
import Network

public actor ClientTransport {
    public enum Event: Sendable {
        case connecting(host: String, port: Int)
        case connected
        case disconnected(reason: String)
        case failed(String)
        case sent
        case received(Data)
    }

    private let manager = ConnectionManager()
    private var connectionID: UUID?

    private var continuation: AsyncStream<Event>.Continuation?
    public private(set) lazy var stream: AsyncStream<Event> = {
        AsyncStream<Event> { cont in
            self.continuation = cont
        }
    }()

    // Heartbeat
    private var heartbeatTask: Task<Void, Never>?
    private var heartbeatConfig = HeartbeatConfig()

    public init(heartbeatConfig: HeartbeatConfig = HeartbeatConfig()) {
        self.heartbeatConfig = heartbeatConfig
    }

    public func events() -> AsyncStream<Event> { stream }

    public func connect(to host: String, port: Int) async throws {
        // Отримуємо id з менеджера
        let id = await manager.connect(to: host, port: port)
        connectionID = id

        // Підписуємося на стрім подій менеджера (отримуємо AsyncStream у акторному контексті)
        let events = await manager.events()

        // Обробляємо події у фоновому таску; всі yield-и робимо через emit(...)
        Task { [weak self] in
            guard let self = self else { return }
            for await state in events {
                // Фільтруємо події по id
                guard state.id == id else { continue }

                switch state.kind {
                case .connecting(let h, let p):
                    await self.emit(.connecting(host: h, port: p))
                case .ready:
                    await self.emit(.connected)
                    await self.startHeartbeat()
                case .disconnected(let reason):
                    await self.emit(.disconnected(reason: reason))
                    await self.stopHeartbeat()
                case .failed(let message):
                    await self.emit(.failed(message))
                    await self.stopHeartbeat()
                case .received(let data):
                    await self.emit(.received(data))
                case .sent:
                    await self.emit(.sent)
                }
            }
        }
    }

    public func disconnect() async {
        await stopHeartbeat()
        if let id = connectionID {
            await manager.disconnect(id, reason: "manual")
        }
        connectionID = nil
    }

    public func send(_ data: Data) async {
        guard let id = connectionID else { return }
        do {
            try await manager.send(id: id, data: data)
        } catch {
            await emit(.failed(error.localizedDescription))
        }
    }

    // MARK: - Heartbeat

    private func startHeartbeat() async {
        await stopHeartbeat()
        heartbeatTask = Task { [weak self] in
            guard let self = self else { return }
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: UInt64(self.heartbeatConfig.interval * 1_000_000_000))
                } catch {
                    break
                }
                let payload = HeartbeatPayload.ping(timestamp: Date().timeIntervalSince1970)
                let envelope = MessageEnvelope(type: .ping, payload: payload)
                if let data = try? JSONEncoder().encode(envelope) {
                    await self.send(data)
                }
            }
        }
    }

    private func stopHeartbeat() async {
        heartbeatTask?.cancel()
        heartbeatTask = nil
    }

    // MARK: - Actor-isolated emitter

    private func emit(_ event: Event) {
        continuation?.yield(event)
    }
}
