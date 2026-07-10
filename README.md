# Serverable

**Serverable** is a modern Swift package for building networking clients and services.

It is designed around a clean, modular architecture with an emphasis on **maintainability**, **security**, and **long-term scalability** across Apple platforms.

---

# Features

- 🚀 Swift Concurrency (`actor`, `Sendable`) first
- 🌐 Bonjour service discovery
- 🔒 TLS pinning support
- 🧩 Modular architecture
- 📦 Simple import model
- 🖥️ Cross-platform (iOS, macOS, command-line tools)
- 🏗️ Production-oriented design

---

# Import Rules

## Full framework

```swift
import Serverable
```

Provides access to the complete public API.

---

## Networking layer only

```swift
import Serverable.CoreNetworking
```

Imports only the networking stack without additional modules.

---

## Unsupported imports

The following modules are intentionally **not** exposed:

```swift
import CoreNetworking          // ❌
import APIModels               // ❌
import Serverable.APIModels    // ❌
```

`APIModels` is considered an implementation detail and should never be imported directly.

---

# Architecture

```text
Serverable
│
├── CoreNetworking
│   ├── ConnectionManager
│   ├── ClientTransport
│   ├── BonjourDiscovery
│   └── BonjourEndpoint
│
└── APIModels
    ├── EndpointDescriptor
    ├── HandshakePayload
    ├── Heartbeat
    └── MessageEnvelope
```

---

## CoreNetworking

The networking layer is built on top of **Foundation** and **Network**.

### Components

| Type | Description |
|------|-------------|
| `ConnectionManager` | Manages the connection lifecycle |
| `ClientTransport` | `actor` responsible for client transport |
| `BonjourDiscovery` | Bonjour service discovery |
| `BonjourEndpoint` | Host and port representation |

---

## APIModels

Contains internal DTOs used by the networking layer.

Examples include:

- `EndpointDescriptor`
- `HandshakePayload`
- `Heartbeat`
- `MessageEnvelope`

> [!NOTE]
> `APIModels` is **internal** and is never imported directly. Public access is provided exclusively through `Serverable`.

---

# Usage

## Full package

```swift
import Serverable

let manager = ConnectionManager()
let transport = ClientTransport()

Task {
    await transport.connect(
        host: "localhost",
        port: 8080
    )
}
```

---

## Networking only

```swift
import Serverable.CoreNetworking

let transport = ClientTransport()

Task {
    await transport.connect(
        host: "example.com",
        port: 443
    )
}
```

---

# Repository Layout

```text
Sources/
├── APIModels/          // Internal DTOs
├── CoreNetworking/     // Networking implementation
└── Serverable/         // Umbrella module
```

---

# Design Principles

- Single umbrella module for the complete public API
- Optional lightweight networking import
- Clear separation between networking and data models
- Internal implementation details remain hidden
- Stable, predictable public API
- Modern Swift architecture
- Designed for long-term evolution

---

# Roadmap

- [ ] Complete unit test coverage
- [ ] API documentation
- [ ] SwiftUI integration examples
- [ ] Server implementation examples
- [ ] Advanced TLS pinning strategies
- [ ] Connection recovery and retry policies
- [ ] Structured logging and diagnostics
- [ ] Metrics and observability hooks
- [ ] Rust-powered `CoreNetworking` (C ABI bridge for Swift)
- [ ] Additional transport implementations (QUIC, WebSocket)

---

# Platform Support

| Platform | Status |
|----------|--------|
| iOS | ✅ |
| macOS | ✅ |
| Command-line tools | ✅ |

---

# Philosophy

Serverable aims to provide a networking foundation that is:

- simple to integrate,
- easy to extend,
- safe by default,
- architecturally clean,
- and suitable for production-scale applications.
