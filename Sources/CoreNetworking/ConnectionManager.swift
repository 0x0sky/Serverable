import Foundation
import Network

public actor ConnectionManager {
    // EventKind як enum з associated values — простіше і інтуїтивніше
    public enum EventKind: Sendable {
        case connecting(host: String, port: Int)
        case ready
        case disconnected(reason: String)
        case failed(String)
        case received(Data)
        case sent
    }

    public struct StateEvent: Sendable {
        public let id: UUID
        public let kind: EventKind
        public init(id: UUID, kind: EventKind) {
            self.id = id
            self.kind = kind
        }
    }

    // MARK: - Storage

    private var connections: [UUID: ConnectionWrapper] = [:]
    private var disconnected: Set<UUID> = []

    private var continuation: AsyncStream<StateEvent>.Continuation?
    public private(set) lazy var stream: AsyncStream<StateEvent> = {
        AsyncStream<StateEvent> { cont in
            self.continuation = cont
        }
    }()

    public init() {}

    public func events() -> AsyncStream<StateEvent> { stream }

    // MARK: - Public API

    public func connect(to host: String, port: Int) async -> UUID {
        let id = UUID()

        guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else {
            await emit(StateEvent(id: id, kind: .failed("Invalid port: \(port)")))
            return id
        }

        let params = NWParameters.tcp
        let queue = DispatchQueue(label: "ConnectionManager.connection.\(id.uuidString)")
        let conn = NWConnection(host: NWEndpoint.Host(host), port: nwPort, using: params)
        let wrapper = ConnectionWrapper(connection: conn, queue: queue)
        connections[id] = wrapper

        await emit(StateEvent(id: id, kind: .connecting(host: host, port: port)))

        conn.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            Task { await self.handleState(state, for: id) }
        }

        conn.start(queue: queue)
        scheduleReceiveLoop(for: id, wrapper: wrapper)

        return id
    }

    public func disconnect(_ id: UUID, reason: String = "manual") async {
        guard !disconnected.contains(id) else { return }
        disconnected.insert(id)

        if let wrapper = connections[id] {
            let connection = wrapper.connection
            let queue = wrapper.queue
            queue.async {
                connection.cancel()
            }
            connections.removeValue(forKey: id)
        }

        await emit(StateEvent(id: id, kind: .disconnected(reason: reason)))
    }

    public func send(id: UUID, data: Data) async throws {
        guard let wrapper = connections[id] else {
            throw NSError(domain: "ConnectionManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Connection not found"])
        }

        let connection = wrapper.connection
        let queue = wrapper.queue

        queue.async {
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    Task { await self.emit(StateEvent(id: id, kind: .failed(error.localizedDescription))) }
                } else {
                    Task { await self.emit(StateEvent(id: id, kind: .sent)) }
                }
            })
        }
    }

    // MARK: - Internal helpers

    private func handleState(_ state: NWConnection.State, for id: UUID) async {
        switch state {
        case .ready:
            await emit(StateEvent(id: id, kind: .ready))
        case .failed(let error):
            await disconnect(id, reason: "failed: \(error.localizedDescription)")
            await emit(StateEvent(id: id, kind: .failed(error.localizedDescription)))
        case .cancelled:
            await disconnect(id, reason: "cancelled")
        default:
            break
        }
    }

    private func scheduleReceiveLoop(for id: UUID, wrapper: ConnectionWrapper) {
        let connection = wrapper.connection
        let queue = wrapper.queue

        queue.async { [weak self] in
            guard let self = self else { return }

            func receiveOnce() {
                connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { data, _, isComplete, error in
                    if let data = data, !data.isEmpty {
                        Task { await self.emit(StateEvent(id: id, kind: .received(data))) }
                    }
                    if let error {
                        Task { await self.emit(StateEvent(id: id, kind: .failed(error.localizedDescription))) }
                    }
                    if isComplete {
                        Task { await self.emit(StateEvent(id: id, kind: .disconnected(reason: "completed"))) }
                    } else {
                        receiveOnce()
                    }
                }
            }

            receiveOnce()
        }
    }

    // Actor-isolated emitter for continuation
    private func emit(_ event: StateEvent) {
        continuation?.yield(event)
    }
}

// MARK: - File-scope ConnectionWrapper and Sendable conformance

private final class ConnectionWrapper {
    let connection: NWConnection
    let queue: DispatchQueue

    init(connection: NWConnection, queue: DispatchQueue) {
        self.connection = connection
        self.queue = queue
    }
}

// Ми гарантуємо, що доступ до `connection` відбувається лише на `queue`.
// Позначаємо як @unchecked Sendable, щоб дозволити захоплення connection/queue у closure, що виконується на цій черзі.
extension ConnectionWrapper: @unchecked Sendable {}
