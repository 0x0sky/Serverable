📘 README.md

Serverable

Serverable — Swift‑бібліотека для побудови мережевих клієнтів та сервісів з акцентом на чисту архітектуру, розширюваність та портативність.

Вона надає два способи імпорту:

• ✅ import Serverable — umbrella, доступ до всіх компонентів.
• ✅ import Serverable.CoreNetworking — лише мережевий шар.
• ❌ import CoreNetworking, import APIModels, import Serverable.APIModels — недоступно.


---

📦 Архітектура

• CoreNetworking
Мережевий шар, що інкапсулює роботу з Network та Foundation:• ConnectionManager — управління життєвим циклом з’єднання
• ClientTransport — актор для клієнтських транспортів з подіями (connecting, connected, failed)
• BonjourDiscovery — пошук сервісів через Bonjour
• BonjourEndpoint — модель для опису хоста/порту

• APIModels
DTO‑структури (EndpointDescriptor, HandshakePayload, Heartbeat, MessageEnvelope).
Вони не імпортуються напряму, а доступні лише через Serverable або Serverable.CoreNetworking.


---

🚀 Можливості

• Єдиний точковий імпорт (import Serverable)
• Альтернативний імпорт лише мережевого шару (import Serverable.CoreNetworking)
• Використання Swift Concurrency (actor, Sendable)
• Підтримка Bonjour для локального сервіс‑дискавері
• Чистий розподіл між моделями даних і мережевою логікою
• Портативність: iOS/macOS додатки та CLI‑утиліти


---

🛠 Використання

import Serverable

let manager = ConnectionManager()
let transport = ClientTransport()

Task {
    await transport.connect(host: "localhost", port: 8080)
}


Або:

import Serverable.CoreNetworking

let transport = ClientTransport()

Task {
    await transport.connect(host: "example.com", port: 443)
}


---

📂 Структура репозиторію

Sources/
 ├── APIModels/        // внутрішні DTO
 ├── CoreNetworking/   // мережевий шар
 └── Serverable/       // umbrella, реекспортує все


---

🔮 Roadmap

• Юніт‑тести для CoreNetworking
• Документація протоколів APIModels
• Приклади інтеграції з iOS UI (SwiftUI)
• Можливість підключення Rust‑модулів через C ABI
