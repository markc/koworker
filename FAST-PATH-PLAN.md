# koworker Fast Path — Implementation Plan

Direct Anthropic API client. Get a working desktop chat agent fast, add mesh later.

---

## Phase 0A — Skeleton (target: first session)

**Goal:** App launches, window appears, can type and see text.

1. **CMakeLists.txt** — Qt6 (Core, Quick, Network, Sql, DBus), QML module, install rules
2. **CMakePresets.json** — debug (ASAN) + release presets
3. **main.cpp** — QGuiApplication, QQmlApplicationEngine, register C++ types
4. **Main.qml** — ApplicationWindow with two-column layout:
   - Left: session list placeholder (narrow)
   - Centre: ChatView with input TextArea + send button
5. **Theme.qml** — QML singleton with colour tokens, spacing, font sizes
   - Dark mode default, honour system colour scheme
   - 4-5 accent palettes (crimson, stone, ocean, forest, sunset)
6. **MessageModel** (C++) — QAbstractListModel with roles: role, content, isStreaming, timestamp
   - `appendMessage(role, content)`, `appendDelta(index, token)`, `finalise(index)`

**Acceptance:** App runs. Type text, press send, message appears in list (no API yet).

---

## Phase 0B — Anthropic Streaming

**Goal:** Send prompt, see streaming response token by token.

1. **AnthropicClient** (C++) — single QObject exposed to QML:
   - `Q_PROPERTY apiKey` — from settings
   - `Q_PROPERTY model` — default claude-sonnet-4-20250514
   - `Q_PROPERTY running READ isRunning NOTIFY runningChanged`
   - `Q_INVOKABLE sendMessage(QString prompt)` — builds messages array, POSTs with stream:true
   - `Q_INVOKABLE cancel()` — aborts active QNetworkReply
   - Signal: `tokenReceived(QString token)` — QML appends to current message
   - Signal: `responseFinished()` — QML finalises message
   - Signal: `errorOccurred(QString error)` — QML shows inline error
   - Internal: SSE line buffer, JSON parsing, conversation history management
2. **ChatView.qml** — wire up:
   - Send button calls `client.sendMessage(inputText)`
   - `onTokenReceived:` appends delta to last assistant message via MessageModel
   - `onResponseFinished:` finalise message, re-enable input
   - Cancel button visible when `client.running`
   - Auto-scroll ListView to bottom on new content
3. **MessageDelegate.qml** — per-message rendering:
   - User: right-aligned, accent background
   - Assistant: left-aligned, `Text { textFormat: Text.MarkdownText }`, updates live
   - Streaming indicator: pulsing cursor at end of assistant message
4. **SettingsDialog.qml** — modal dialog:
   - API key field (password echo mode)
   - Model selector (dropdown: opus, sonnet, haiku)
   - Stored via Qt.labs.settings

**Acceptance:** Enter API key. Type a prompt. See streaming Markdown response.

---

## Phase 0C — Conversation Context

**Goal:** Multi-turn conversation works. System prompt configurable.

1. **AnthropicClient** conversation management:
   - Maintains `QJsonArray m_messages` (the messages array sent to API)
   - Each sendMessage() appends user message, sends full array
   - On response complete, appends assistant message to array
   - `Q_INVOKABLE newSession()` — clears messages array
   - `Q_PROPERTY systemPrompt` — prepended as system parameter
2. **System prompt** in SettingsDialog — multiline TextArea, saved to settings
3. **New Session button** in sidebar — clears chat, starts fresh context

**Acceptance:** Multi-turn conversation. Claude remembers prior messages in session.

---

## Phase 1 — History

**Goal:** Sessions persist across app restarts.

1. **HistoryStore** (C++) — QObject wrapping QSqlDatabase:
   - `init()` — creates/opens ~/.local/share/koworker/history.db, runs migrations
   - `createSession() → QString id`
   - `saveMessage(sessionId, role, content, toolData)`
   - `loadSession(sessionId) → QJsonArray messages`
   - `listSessions() → QJsonArray` (id, title, updatedAt)
   - `deleteSession(sessionId)`
   - `updateTitle(sessionId, title)`
   - Session title: first 60 chars of first user message (auto, no API call)
2. **HistoryDrawer.qml** — left sidebar:
   - ListView of sessions (title, relative date)
   - Click to load session into ChatView
   - Swipe or right-click to delete
   - "New Session" button at top
   - Search field filtering by title
3. **Auto-save** — every message saved to SQLite as it arrives

**Acceptance:** Close app, reopen. Sessions visible in sidebar. Click to restore.

---

## Phase 2 — Tool Use

**Goal:** Claude can call tools. Permission gate before execution.

1. **Tool loop in AnthropicClient:**
   - Parse `content_block_start` with `type: "tool_use"` → extract name, input
   - Emit `toolCallRequested(QString name, QJsonObject input, QString toolUseId)`
   - QML shows ToolCallDelegate (collapsible: tool name, args, status)
   - QML (or C++ PermissionGate) checks allowed paths
   - If allowed: execute tool, call `client.submitToolResult(toolUseId, result)`
   - `submitToolResult()` appends tool_result to messages, sends next API request
   - Loop continues until `stop_reason: "end_turn"`
2. **Built-in tools** (registered in AnthropicClient tool definitions):
   - `read_file` — QFile read, returns content
   - `write_file` — QFile write (permission gated)
   - `list_directory` — QDir listing
   - `run_command` — QProcess (permission gated, timeout 30s)
3. **PermissionGate** — QML component:
   - Configured allowed paths list (from Settings)
   - Auto-approve reads within allowed paths
   - Dialog prompt for writes, deletes, and commands
   - "Always allow" option per path
4. **ToolCallDelegate.qml:**
   - Collapsible card showing tool name + arguments
   - Status: pending → running → complete/failed
   - Expandable output preview

**Acceptance:** Ask Claude to read a file. Permission dialog appears. Approve. Result shown.

---

## Phase 3 — Polish

**Goal:** Daily-driver quality.

1. **Code block improvements:**
   - Copy button on code blocks (Clipboard via QML)
   - Monospace font for code
2. **System tray:**
   - QSystemTrayIcon with show/hide toggle
   - Notification when background task completes
3. **Keyboard shortcuts:**
   - Ctrl+Enter to send
   - Ctrl+N for new session
   - Escape to cancel running request
   - Ctrl+, for settings
4. **Error handling:**
   - Network errors shown inline
   - Rate limit detection with retry suggestion
   - Invalid API key detection on first request
5. **Dark/light mode toggle** — follows system, manual override in settings

**Acceptance:** Usable as daily chat/agent tool on Plasma desktop.

---

## Future Phases (not in fast path)

| Phase | Feature | Trigger |
|-------|---------|---------|
| 4 | D-Bus AppMeshBridge | When appmesh D-Bus tools needed from koworker |
| 5 | nodemesh AMP backend | When Laravel agent bridge exists in markweb |
| 6 | MeshView (node status) | When multi-node mesh is deployed |
| 7 | Scheduler (systemd timers) | When recurring tasks needed |
| 8 | PKGBUILD + packaging | When ready for distribution |

---

## Key Design Decisions

### QML-first, C++-minimal

| QML does | C++ does |
|----------|----------|
| All layout, styling, animation | HTTP streaming (QNetworkAccessManager) |
| State machine (idle/running/error) | SSE parsing (byte-level buffering) |
| Settings UI + persistence | SQLite read/write |
| Permission dialog logic | QAbstractListModel for messages |
| Input handling, scroll behaviour | D-Bus adaptor (future) |
| Theme switching | QProcess for tool execution |

### No Kirigami, no KDE Frameworks

Plain Qt6 only. Looks native on Plasma via org.kde.desktop style (ships with Plasma).
No extra dependencies to install, no framework version conflicts.

### Direct API first, mesh later

AnthropicClient is a clean interface:
- `sendMessage(prompt)` / `cancel()` / `submitToolResult(id, result)`
- Signals: `tokenReceived` / `responseFinished` / `toolCallRequested` / `errorOccurred`

Swapping to nodemesh = replace AnthropicClient internals with QWebSocket + AMP framing.
The QML layer doesn't change at all.

### Model default

claude-sonnet-4-20250514 — fast enough for interactive use, capable enough for tool use.
User can switch to opus/haiku in settings.

---

## Build prerequisites (CachyOS/Arch)

```bash
sudo pacman -S qt6-base qt6-declarative qt6-websockets cmake
```

No ECM, no KDE Frameworks, no npm, no node.
