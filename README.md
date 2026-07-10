Serverable

Serverable is a Swift library built for networking clients and services. The design is clean, extensible, and portable — engineered for teams that care about architecture and long‑term maintainability.

Import rules

• ✅ import Serverable — umbrella, full access
• ✅ import Serverable.CoreNetworking — networking layer only
• ❌ import CoreNetworking, import APIModels, import Serverable.APIModels — not available


---

Architecture

CoreNetworking
Networking layer built on Network and Foundation:

• ConnectionManager — connection lifecycle management
• ClientTransport — actor handling client transport events (connecting, connected, failed)
• BonjourDiscovery — Bonjour service discovery
• BonjourEndpoint — host/port model


APIModels
DTOs (EndpointDescriptor, HandshakePayload, Heartbeat, MessageEnvelope).
Internal only — exposed through Serverable or Serverable.CoreNetworking, never imported directly.

---

Capabilities

• Single import for full stack (import Serverable)
• Optional import for networking only (import Serverable.CoreNetworking)
• Swift Concurrency (actor, Sendable) baked in
• Bonjour discovery support
• Clear separation of data models and networking logic
• Portable across iOS, macOS, and CLI utilities


---

Usage

import Serverable

let manager = ConnectionManager()
let transport = ClientTransport()

Task {
    await transport.connect(host: "localhost", port: 8080)
}


Or:

import Serverable.CoreNetworking

let transport = ClientTransport()

Task {
    await transport.connect(host: "example.com", port: 443)
}


---

Repository Layout

Sources/
 ├── APIModels/        // internal DTOs
 ├── CoreNetworking/   // networking layer
 └── Serverable/       // umbrella, re‑exports everything


---

Roadmap

• Unit tests for CoreNetworking
• Documentation for APIModels
• SwiftUI integration examples
• Rust rewrite of CoreNetworking for performance and portability (C ABI bridge to Swift)
