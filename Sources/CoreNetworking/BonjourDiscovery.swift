import Foundation

public struct BonjourEndpoint: Sendable {
    public let host: String
    public let port: Int

    public init(host: String, port: Int) {
        self.host = host
        self.port = port
    }
}

public actor BonjourDiscovery {
    public enum Event: Sendable {
        case started
        case stopped
        case error(String)
        case removed(name: String)
    }

    // MARK: - Streams

    private var endpointCont: AsyncStream<BonjourEndpoint>.Continuation?
    public private(set) lazy var endpoints: AsyncStream<BonjourEndpoint> = {
        var localCont: AsyncStream<BonjourEndpoint>.Continuation?
        let stream = AsyncStream<BonjourEndpoint> { cont in
            localCont = cont
        }
        endpointCont = localCont
        return stream
    }()

    private var eventCont: AsyncStream<Event>.Continuation?
    public private(set) lazy var events: AsyncStream<Event> = {
        var localCont: AsyncStream<Event>.Continuation?
        let stream = AsyncStream<Event> { cont in
            localCont = cont
        }
        eventCont = localCont
        return stream
    }()

    // MARK: - Delegate proxy and browser

    private var delegateProxy: DelegateProxy?
    private let browser: NetServiceBrowser

    public init() {
        browser = NetServiceBrowser()
        // Defer creation of the proxy to actor context to avoid accessing actor-isolated
        // properties from a nonisolated initializer.
        Task { await self.setupDelegate() }
    }

    private func setupDelegate() {
        let proxy = DelegateProxy(owner: self)
        delegateProxy = proxy
        browser.delegate = proxy
    }

    // MARK: - Public API

    /// Start discovery for given service type and domain.
    /// Example type: "_http._tcp."
    public func discover(type: String, domain: String = "") {
        delegateProxy?.searchForServices(ofType: type, inDomain: domain)
    }

    public func stop() {
        delegateProxy?.stop()
        eventCont?.yield(.stopped)
    }

    // MARK: - Actor-isolated handlers (receive only Sendable data)

    fileprivate func handleWillSearch() {
        eventCont?.yield(.started)
    }

    fileprivate func handleDidStopSearch() {
        eventCont?.yield(.stopped)
    }

    fileprivate func handleDidNotSearch(_ errorDescription: String) {
        eventCont?.yield(.error(errorDescription))
    }

    fileprivate func handleDidFindService(name: String) {
        // informational; resolution handled by DelegateProxy
    }

    fileprivate func handleDidRemoveService(name: String) {
        eventCont?.yield(.removed(name: name))
    }

    fileprivate func handleResolvedEndpoint(host: String, port: Int) {
        endpointCont?.yield(BonjourEndpoint(host: host, port: port))
    }

    fileprivate func handleDidNotResolve(_ errorDescription: String) {
        eventCont?.yield(.error(errorDescription))
    }
}

// MARK: - DelegateProxy (non-actor)

private final class DelegateProxy: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    private weak var owner: BonjourDiscovery?
    private let browser = NetServiceBrowser()
    private var services: [NetService] = []

    init(owner: BonjourDiscovery) {
        self.owner = owner
        super.init()
        browser.delegate = self
    }

    // Control methods used by actor
    func searchForServices(ofType type: String, inDomain domain: String) {
        browser.searchForServices(ofType: type, inDomain: domain)
    }

    func stop() {
        browser.stop()
    }

    // MARK: - NetServiceBrowserDelegate

    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        Task { [weak owner] in
            await owner?.handleWillSearch()
        }
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        Task { [weak owner] in
            await owner?.handleDidStopSearch()
        }
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        let desc = Self.description(from: errorDict)
        Task { [weak owner] in
            await owner?.handleDidNotSearch(desc)
        }
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        // Keep a strong reference while resolving
        services.append(service)
        service.delegate = self
        service.resolve(withTimeout: 5)

        let nameCopy = service.name
        Task { [weak owner] in
            await owner?.handleDidFindService(name: nameCopy)
        }
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        services.removeAll { $0 === service }
        let nameCopy = service.name
        Task { [weak owner] in
            await owner?.handleDidRemoveService(name: nameCopy)
        }
    }

    // MARK: - NetServiceDelegate

    func netServiceDidResolveAddress(_ service: NetService) {
        // Copy simple values to avoid capturing `service` in @Sendable closures
        let serviceName = service.name
        let servicePort = service.port
        let serviceHostName = service.hostName

        // If hostName is available and port valid, report immediately
        if let hostName = serviceHostName, servicePort != -1 {
            Task { [weak owner] in
                await owner?.handleResolvedEndpoint(host: hostName, port: servicePort)
            }
            return
        }

        guard let addrs = service.addresses else {
            Task { [weak owner] in
                await owner?.handleDidNotResolve("No addresses for service \(serviceName)")
            }
            return
        }

        for addr in addrs {
            // Work with a copy of Data to avoid capturing NetService
            let dataCopy = Data(addr)
            let fallbackPort = servicePort

            dataCopy.withUnsafeBytes { rawBuf in
                guard let base = rawBuf.baseAddress else { return }
                let family = base.assumingMemoryBound(to: sockaddr.self).pointee.sa_family

                if family == sa_family_t(AF_INET) {
                    let addrIn = base.assumingMemoryBound(to: sockaddr_in.self).pointee
                    let portFromData = Int(UInt16(bigEndian: addrIn.sin_port))
                    var addr = addrIn.sin_addr
                    var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                    inet_ntop(AF_INET, &addr, &buffer, socklen_t(INET_ADDRSTRLEN))
                    let ip = String(cString: buffer)

                    Task { [weak owner] in
                        let portToUse = portFromData != 0 ? portFromData : fallbackPort
                        await owner?.handleResolvedEndpoint(host: ip, port: portToUse)
                    }
                } else if family == sa_family_t(AF_INET6) {
                    let addrIn6 = base.assumingMemoryBound(to: sockaddr_in6.self).pointee
                    let portFromData = Int(UInt16(bigEndian: addrIn6.sin6_port))
                    var addr6 = addrIn6.sin6_addr
                    var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
                    inet_ntop(AF_INET6, &addr6, &buffer, socklen_t(INET6_ADDRSTRLEN))
                    let ip = String(cString: buffer)

                    Task { [weak owner] in
                        let portToUse = portFromData != 0 ? portFromData : fallbackPort
                        await owner?.handleResolvedEndpoint(host: ip, port: portToUse)
                    }
                }
            }
        }
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        let desc = Self.description(from: errorDict)
        Task { [weak owner] in
            await owner?.handleDidNotResolve(desc)
        }
    }

    // MARK: - Helpers

    private static func description(from errorDict: [String: NSNumber]) -> String {
        if let code = errorDict["NSNetServicesErrorCode"] {
            return "NetService error code: \(code)"
        }
        return errorDict.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
    }
}
