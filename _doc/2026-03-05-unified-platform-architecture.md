# The Unified Platform: koworker, appmesh, nodemesh, markweb

How four projects converge into one cohesive system — a native Plasma desktop
implementation backed by a Laravel + React web interface, so the full framework
works from any browser on any OS while CachyOS/Plasma users get the real thing.

---

## The Vision

One distributed AI agent platform with two equal-citizen frontends:

1. **Browser (any OS):** markweb — Laravel 12 + Inertia 2 + React 19, full-featured
   web application with streaming chat, mail, mesh dashboard, task planning.

2. **Plasma desktop (Linux):** koworker — Qt6/QML native app with system tray,
   global hotkey, D-Bus integration, Plasma plasmoids, direct desktop automation.

Both frontends speak the same protocol (AMP), connect to the same mesh (nodemesh),
and can orchestrate the same desktop tools (appmesh). The browser version works
from a phone, a Mac, or a Chromebook. The desktop version is for us.

---

## The Four Projects

### markweb — The Web Platform

**Repo:** `~/.gh/markweb` | **Stack:** Laravel 12, Inertia 2, React 19, PostgreSQL + pgvector

The monolith. Three application layers on every node:

| Layer | What it does |
|-------|-------------|
| **AI Agent Platform** | Multi-model chat (7 providers, Anthropic primary), tool use, semantic memory (pgvector embeddings via Ollama), sandboxed code execution, scheduled routines |
| **JMAP Webmail + PIM** | Full email client via Stalwart Mail Server (JMAP), CalDAV/CardDAV contacts and calendars (SabreDAV) |
| **Mesh Command & Control** | Real-time dashboard for the WireGuard cluster, heartbeat monitoring, node coordination |

**Key architectural patterns:**
- **Dual Carousel Sidebars (DCS):** 7 left panels + 3 right panels, glassmorphism, OKLCH colour schemes
- **Streaming:** Laravel Reverb WebSocket for real-time token streaming and events
- **Wayfinder:** Type-safe TypeScript route/action generation — never hand-edit route files
- **Markdown-native:** Every message is simultaneously human-readable, machine-parseable, and LLM-native

**Why it matters to koworker:** markweb is the web-accessible version of everything koworker does natively on the desktop. Same agent sessions, same mesh nodes, same tools — different rendering layer. When koworker connects to nodemesh, it reaches the same agent runtime that markweb's React frontend talks to via Reverb.

---

### nodemesh — The Networking Backbone

**Repo:** `~/.gh/nodemesh` | **Stack:** Rust, tokio, tungstenite, axum, str0m (WebRTC)

A single Rust binary (`meshd`) running on every node. Three interfaces:

```
meshd
 |- Peer WebSocket (port 9800)      inter-node AMP messages over WireGuard
 |- Bridge Unix Socket (meshd.sock)  Laravel sends/receives AMP locally
 |- WebRTC Media (Phase 5)           UDP audio/video/screen via str0m SFU
```

**What it solves:** Replaces HTTP POST heartbeats with persistent WebSocket connections.
Every node maintains a full mesh — if node A can reach node B, messages route
automatically. No centralized broker.

**AMP protocol** (the wire format everything speaks):

```
---
amp: 1
from: agent.markweb.cachyos.amp
to: inbox.stalwart.mko.amp
command: list
session: 550e8400-e29b-41d4-a716-446655440000
---
Optional markdown body here.
```

Addresses are DNS-style: `{port}.{app}.{node}.amp`. Machines route on headers,
humans read the body, LLMs understand both.

**Peer connection model:**
- Both directions attempted; lower WireGuard IP wins on collision
- 15s keepalive (empty AMP frame), exponential backoff reconnection
- Phase 4 adds DNS SRV discovery (replace static TOML config)

**Why it matters to koworker:** nodemesh is koworker's backend. In the full
architecture, koworker doesn't call the Anthropic API — it sends AMP frames to
meshd, which handles LLM routing, tool execution, MCP servers, and agent session
management. The fast-path (Phase 0) shortcuts this by talking to Anthropic
directly, but the QML interface is designed so swapping `AnthropicClient` for
`AmpClient` changes zero QML code.

---

### appmesh — Desktop Automation

**Repo:** `~/.gh/appmesh` | **Stack:** Rust (core), PHP (MCP server), C++/Qt6 (QML plugin), QML (plasmoids)

The ARexx of Linux. Makes every desktop app scriptable through a unified interface.

**89 tools across 11 plugins:**

| Plugin | Tools | Domain |
|--------|-------|--------|
| `ports.php` | 23 | Rust FFI — input, clipboard, notify, screenshot, windows, mail |
| `editor.php` | 12 | KTextEditor (Kate/KWrite) via custom D-Bus plugin |
| `config.php` | 11 | KDE/KConfig themes and settings |
| `dbus.php` | 8 | Generic D-Bus (notifications, screenshots, clipboard) |
| `midi.php` | 8 | PipeWire MIDI routing |
| `cdp.php` | 6 | Chrome DevTools Protocol (Electron apps) |
| `tts.php` | 6 | Google Gemini TTS + tutorial video pipeline |
| `websocket.php` | 6 | WebSocket gateway lifecycle |
| `osc.php` | 3 | OSC/UDP (Ardour DAW, Carla) |
| `socket.php` | 4 | AMP Unix socket server |
| `keyboard.php` | 2 | KWin EIS keyboard injection |

**Rust core** (`libappmesh_core.so`): 8 C ABI symbols, 6 ports implementing the
`AppMeshPort` trait. PHP calls Rust via FFI at ~0.05ms per call. Each port creates
its own tokio runtime.

**Desktop integration:**
- 2 Plasma 6 plasmoids (Mesh Send, Mesh Log)
- KTextEditor D-Bus plugin (19 methods, 2 signals — works in Kate, KWrite, KDevelop)
- KWin EIS keyboard injection via libei
- Web UI at localhost:8420 (HTMX + SSE)

**Why it matters to koworker:** appmesh is koworker's hands. When an agent needs
to type text into Kate, take a screenshot, read the clipboard, or control
PipeWire — those capabilities come from appmesh ports. In the full architecture:

```
User types prompt in koworker
  -> AMP frame to nodemesh
  -> nodemesh calls tool (e.g. "paste clipboard contents")
  -> nodemesh dispatches to appmesh port via D-Bus or Unix socket
  -> appmesh executes (Rust FFI -> D-Bus -> Klipper)
  -> result flows back: appmesh -> nodemesh -> koworker
```

---

### koworker — The Native Desktop Frontend

**Repo:** `~/.gh/koworker` | **Stack:** C++17, Qt6, QML, CMake

The Plasma-native AI agent interface. What the user sees and interacts with.

**Current approach (fast path):** Direct Anthropic API via `QNetworkAccessManager`
with SSE streaming. Gets a working desktop chat agent fast. The `AnthropicClient`
C++ class has a clean signal interface (`tokenReceived`, `responseFinished`,
`toolCallRequested`, `errorOccurred`) that QML binds to.

**Future approach (mesh):** Replace `AnthropicClient` internals with `AmpClient`
(QWebSocket + AMP framing). Zero QML changes — the signal interface is identical.

**Design principles:**
- **QML-first:** All UI logic in QML. C++ only for things QML can't do (HTTP streaming, SQLite, D-Bus)
- **No Kirigami:** Plain QtQuick Controls 2, looks native via `org.kde.desktop` style
- **No KDE Frameworks runtime dependency** (ECM at build time only)
- **Plasma-native features:** System tray, global hotkey (Meta+K), D-Bus service (`org.kde.koworker`), plasmoid integration

---

## How They Connect

### The Data Flow

```
                    Browser (any OS)
                         |
                    markweb (Laravel)
                    React + Reverb WS
                         |
                    -----+-----
                    |         |
               nodemesh    nodemesh    <-- Rust daemons, one per node
              (cachyos)     (mko)         connected via WireGuard
                    |         |
                    -----+-----
                         |
                    AMP protocol
                    (WebSocket)
                         |
              koworker (Plasma)     <-- native desktop, same mesh
                         |
                    D-Bus / FFI
                         |
                    appmesh          <-- desktop automation
                    (ports, plugins, plasmoids)
```

### The Three-Node Mesh

| Node | Domain | WireGuard IP | Role |
|------|--------|-------------|------|
| **cachyos** | web.goldcoast.org | 172.16.2.5 | Dev workstation (where koworker runs) |
| **mko** | web.kanary.org | 172.16.2.210 | Production primary, registry authority |
| **mmc** | web.motd.com | 172.16.2.9 | Production secondary |

Every node runs: FrankenPHP (Caddy), PostgreSQL + pgvector, Ollama, Laravel Reverb,
meshd. The mesh is symmetric — any node can reach any other.

### Protocol Unification: AMP

AMP is the lingua franca. Every component speaks it:

| Component | How it uses AMP |
|-----------|----------------|
| **nodemesh** | Native format — meshd routes AMP frames between peers |
| **markweb** | Sends/receives via Unix socket bridge to local meshd |
| **koworker** | Sends/receives via WebSocket to meshd |
| **appmesh** | Receives commands via AMP, responds with results |
| **Plasmoids** | Lightweight AMP UI (send/log) on the Plasma panel |

The **three-reader principle**: every AMP message is readable by machines (deterministic
headers for routing), humans (`cat` it in a terminal), and LLMs (markdown body).

---

## The Convergence Path

### Today (March 2026)

- **markweb** is the most mature — full agent platform, mail, mesh C&C
- **nodemesh** has peer connections and bridge working, WebRTC SFU in progress
- **appmesh** has 89 tools, Rust ports, plasmoids, MCP server for Claude Code
- **koworker** has CLAUDE.md and implementation plans, no code yet

### Near-term: koworker Phase 0 (fast path)

Build the desktop app with direct Anthropic API. Get streaming chat, history,
tool use, and permission gates working. This is useful immediately — a native
Plasma Claude chat app.

### Mid-term: Mesh integration

Replace `AnthropicClient` with `AmpClient`. koworker becomes a mesh citizen:
- Sessions routed through nodemesh (access all 7 LLM providers, not just Anthropic)
- Tools dispatched to appmesh ports (desktop automation from chat)
- Session state shared — start a conversation in the browser, continue on desktop
- D-Bus service lets other Plasma apps trigger agent tasks

### Long-term: Single cohesive Plasma project

The four repos could merge or stay separate but install as one:
- `meshd` runs as a systemd service (always on)
- `koworker` is the desktop app (tray + window)
- `appmesh` ports register automatically when koworker starts
- markweb is the web fallback (same backend, browser rendering)
- Plasmoids on the panel for quick actions
- Global hotkey (Meta+K) summons the agent from anywhere
- Scheduled tasks via systemd user timers

**The pitch:** Your Linux desktop becomes an intelligent mesh node. Every app is
scriptable, every conversation persists, every tool is permission-gated, and the
whole thing works from your phone too via the web interface.

---

## Shared Design Decisions

### Stack alignment

| Decision | All projects |
|----------|-------------|
| No Docker | Incus or Proxmox, or bare metal |
| WireGuard transport | Private mesh, no NAT complexity |
| PostgreSQL + pgvector | Embeddings and full-text search |
| Ollama | Local inference (nomic-embed-text for embeddings, code/chat models) |
| OKLCH colour schemes | 5 palettes shared between markweb Theme and koworker Theme.qml |
| FrankenPHP (Caddy) | Multi-project HTTP server |
| Markdown everywhere | Messages, docs, wire format, rendering |

### What each project owns

| Concern | Owner |
|---------|-------|
| LLM API calls | nodemesh (or koworker in fast-path) |
| Tool execution | appmesh (desktop), nodemesh (sandboxed) |
| Web UI | markweb |
| Desktop UI | koworker |
| Inter-node routing | nodemesh |
| D-Bus / desktop integration | appmesh + koworker |
| Data persistence (web) | markweb (PostgreSQL) |
| Data persistence (desktop) | koworker (SQLite) |
| Media streaming (WebRTC) | nodemesh SFU |
| Mail | markweb (Stalwart JMAP) |

---

## Why Not Just Use the Browser?

Because a native Plasma app can:

- **Inject keystrokes** into any window (libei/EIS)
- **Control Kate** via D-Bus (read/write buffers, find/replace, navigate)
- **Manage PipeWire** audio routing (MIDI, capture, playback)
- **Take screenshots** and read the clipboard without browser permissions
- **Run as a systemd service** with scheduled agent tasks
- **Expose a D-Bus interface** so Dolphin scripts, KRunner, and custom plasmoids can trigger tasks
- **Work offline** against local Ollama models (no cloud needed)
- **Use global hotkeys** from any context (Meta+K to summon)
- **Integrate with Plasma panels** via native QML plasmoids

The browser version is for when you're on your phone, a shared machine, or helping
someone else on their computer. The desktop version is for your daily driver.
Both are first-class citizens of the same platform.
