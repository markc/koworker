# koworker — Claude Code Project Instructions

## What this project is

A Qt6/QML native Linux desktop agent frontend. Phase 0 (fast path): talks directly
to the Anthropic API via QNetworkAccessManager + SSE streaming. Future: switches to
nodemesh AMP WebSocket when the Laravel agent bridge is ready.

**QML-first:** All UI logic lives in QML. C++ is only for backend services that QML
cannot do (HTTP streaming, SQLite, D-Bus adaptor). If QML can do it, do it in QML.

## Language and framework rules

- C++17 only. No C++20 features unless confirmed available on Qt 6.8 LTS.
- Qt6 only. No Qt5 compatibility shims.
- QML for ALL UI and UI logic. No QtWidgets except QSystemTrayIcon.
- CMake build system. No ECM/KDE dependency for Phase 0 — plain Qt6.
- No Kirigami. Use plain QtQuick Controls 2 with Material or org.kde.desktop style.
- All QObjects registered to QML via QML_ELEMENT macro (Qt6 declarative registration).
- Prefer QML singletons and JS logic over C++ QObjects where possible.

## File layout

```
koworker/
├── CLAUDE.md
├── CMakeLists.txt
├── CMakePresets.json
├── src/
│   ├── main.cpp              # QGuiApplication, engine setup, context properties
│   ├── AnthropicClient.h/cpp # QNetworkAccessManager SSE streaming
│   ├── MessageModel.h/cpp    # QAbstractListModel for chat messages
│   ├── HistoryStore.h/cpp    # SQLite via QSqlDatabase
│   └── AppMeshBridge.h/cpp   # QDBusAdaptor (Phase 5, stub for now)
├── qml/
│   ├── Main.qml              # ApplicationWindow, sidebar + main area
│   ├── ChatView.qml          # Message list + input bar
│   ├── MessageDelegate.qml   # Per-message bubble (Markdown rendering)
│   ├── ToolCallDelegate.qml  # Collapsible tool call display
│   ├── HistoryDrawer.qml     # Past sessions sidebar
│   ├── SettingsDialog.qml    # API key, model, allowed paths
│   └── Theme.qml             # Colour tokens, spacing, font sizes
└── assets/
    ├── koworker.svg
    └── koworker.desktop
```

## Architecture (Phase 0 — Direct API)

```
QML UI (ChatView, HistoryDrawer, Settings)
    │ Q_PROPERTY bindings / signals
    ▼
AnthropicClient (C++)
    ├─ streamMessage()    → POST /v1/messages with stream:true
    ├─ handleSSEChunk()   → parse data: lines, emit tokenReceived()
    ├─ toolLoop()         → tool_use → execute → tool_result → continue
    └─ cancelRequest()    → abort QNetworkReply
    │
MessageModel (C++)         HistoryStore (C++)
    ├─ appendDelta()       ├─ SQLite ~/.local/share/koworker/history.db
    ├─ finalise()          ├─ saveMessage() / loadSession()
    └─ roles for QML       └─ listSessions() / deleteSession()
```

## Anthropic API integration

- Endpoint: https://api.anthropic.com/v1/messages
- Model: claude-sonnet-4-20250514 (default, configurable)
- Streaming: SSE with `stream: true`
- Tool use: parse `content_block_start` with `type: "tool_use"`, execute locally,
  return `tool_result` in next request, loop until `stop_reason: "end_turn"`
- Headers: `x-api-key`, `anthropic-version: 2023-06-01`, `content-type: application/json`

## SSE parsing

QNetworkReply emits readyRead(). Buffer incoming bytes, split on `\n\n`,
parse each chunk:
- Lines starting with `event:` → event type
- Lines starting with `data:` → JSON payload
- Key events: `content_block_delta` (text token), `content_block_start` (tool_use),
  `message_delta` (stop_reason), `message_stop`

## State management

- All UI state in QML properties. C++ exposes models and service objects.
- AgentSession state machine lives in QML (idle/running/awaitingPermission/error).
  C++ AnthropicClient emits signals; QML transitions state.
- Settings stored via Qt.labs.settings (QML) backed by ~/.config/koworker/koworker.conf

## SQLite schema

```sql
CREATE TABLE sessions (
    id TEXT PRIMARY KEY,
    title TEXT,
    created_at INTEGER,
    updated_at INTEGER
);
CREATE TABLE messages (
    id TEXT PRIMARY KEY,
    session_id TEXT REFERENCES sessions(id),
    role TEXT,        -- user, assistant, tool_use, tool_result
    content TEXT,
    tool_data TEXT,   -- JSON for tool calls
    timestamp INTEGER
);
```

Versioned migrations via PRAGMA user_version.

## Tool execution (Phase 0)

Phase 0 tools are optional. Start with no tools — pure chat. Add tools incrementally:
1. File read/write via QFile (with permission gate)
2. Shell commands via QProcess (with permission gate)
3. appmesh port commands via D-Bus or Unix socket

## What NOT to do

- Do not add Kirigami, KDE Frameworks, or ECM dependencies.
- Do not put UI logic in C++. State machines, animations, layout — all QML.
- Do not use QVariantMap for API payloads. Use QJsonObject with typed helpers.
- Do not add nodemesh/AMP code yet. Phase 0 is direct API only.
- Do not over-engineer. Get streaming chat working first, everything else follows.
- Do not use WebEngine for Markdown. Use Text { textFormat: Text.MarkdownText }.

## Build

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build
./build/koworker
```

## Naming

Binary: `koworker`. Config: `~/.config/koworker/`. Data: `~/.local/share/koworker/`.
