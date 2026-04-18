KairOS – Final Definitive Blueprint (v1.2)
Codex‑Ready Build Specification
Updated to reflect implementation adjustments and additions. All design decisions are locked.

Table of Contents
System Overview

Architecture Diagram

UI Visual System (Industrial Telemetry)

Data Models (Final Schemas)

Networking & Protocols

Security & Encryption Model

Home Node Service (Linux)

iOS App Implementation (SwiftUI)

ALICE AI Runtime (ALICE 2.0 → ALICE Lite)

App System & SDK

Blackbox Format & Restore Logic

Implementation Roadmap

Testing & Validation

Conclusion

1. System Overview
KairOS is a single iOS application that presents an industrial, terminal‑style interface for secure messaging, file transfer, voice calls, and AI‑assisted operation. All communication is routed through a trusted Home Node (Linux/Chromebook) over a private Tailscale network (Tailnet). The node handles identity, encryption/decryption, routing, and persistent memory for AI. The iOS app is stateless; a Blackbox encrypted snapshot file provides backup and restore via the Files app.

Key Design Pillars (Locked)
Pillar	Description
Node‑centric authority	Node manages encryption keys, device activation, trust graph, AI memory.
KairOS Number (K‑number)	Persistent identity handle. Format: K-XXXX (4 digits for memorability).
Fire‑and‑forget messaging	Queued retry via node; best‑effort delivery; failed items never auto‑deleted.
Hybrid AI (ALICE Lite)	Local LLM distilled from ALICE 2.0; node stores long‑term memory.
Sandboxed apps	Internal modules with tab containers, event bus, self‑contained manifests.
Diegetic industrial UI	Yellow/black duotone, layered typography, panel‑based navigation.
Blackbox persistence	Encrypted snapshot export/import bypasses iOS sandbox deletion.
2. Architecture Diagram
text
┌─────────────────────────────────────────────────────────────────┐
│                         iOS Device                              │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                  KairOS App Container                     │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────┐  │   │
│  │  │ UI Shell│  │ALICE Lite│ │App Runtime│  │Local Cache │  │   │
│  │  │(SwiftUI)│  │(Core ML) │  │(Sandbox) │  │(SQLite/FS) │  │   │
│  │  └────┬────┘  └────┬────┘  └────┬─────┘  └──────┬──────┘  │   │
│  │       │            │            │                │         │   │
│  │       └────────────┴────────────┴────────────────┘         │   │
│  │                         │                                   │   │
│  │               KairOS Core Services                          │   │
│  │   (Networking, Encryption, Identity, Blackbox)              │   │
│  └─────────────────────────┬───────────────────────────────────┘   │
│                            │                                       │
│                   Tailscale VPN (Tailnet)                           │
└────────────────────────────┼───────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Home Node (Linux)                         │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    Node Daemon (Go)                        │  │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────┐ │  │
│  │  │Identity    │ │Encryption  │ │Queue Mgr   │ │Trust   │ │  │
│  │  │Registry    │ │Service     │ │            │ │Graph   │ │  │
│  │  └────────────┘ └────────────┘ └────────────┘ └────────┘ │  │
│  │  ┌────────────────────────────────────────────────────┐   │  │
│  │  │              Persistent Storage (SQLite)            │   │  │
│  │  │  • Device registry  • Trust scores  • Message queue│   │  │
│  │  │  • AI memory graph  • Routing hints                │   │  │
│  │  └────────────────────────────────────────────────────┘   │  │
│  └───────────────────────────────────────────────────────────┘  │
│                            │                                      │
│                   Tailscale VPN (Tailnet)                         │
└────────────────────────────┼──────────────────────────────────────┘
                             │
                             ▼
              Other KairOS Devices (future expansion)
3. UI Visual System (Industrial Telemetry)
3.1 Color Palette (Locked)
Role	Hex Code	Usage
Background	#FFE258FF (RGB: 1.0, 0.886, 0.345)	Main canvas, caution‑yellow
Primary text / UI dark	#332C0CFF (RGB: 0.2, 0.173, 0.047)	Text, borders, active elements
Accent / LED	#D8BF4DFF (RGB: 0.847, 0.749, 0.302)	Indicators, highlights
Grid	#C1A941 (RGB: 0.756, 0.663, 0.255)	Telemetry grid overlay
Alert	#F2411A (RGB: 0.949, 0.255, 0.106)	System errors, warnings
Muted	#746421 (RGB: 0.454, 0.392, 0.129)	Secondary text, disabled elements
Rules: No obvious gradients, no transparency layering, no modern app UI metaphors. Subtle gradients allowed for stylistic depth (e.g., LED glow, panel depth, scanline effects) but should be minimal and not distract from industrial aesthetic. Optional user color wheel allowed but defaults to these. Users may customize both colors and fonts via app settings.

3.2 Typography System
Font Class	Font Name	Usage
Micro tab	"europa-grotesk-sh-bold" (12pt)	Navigation labels
Header	"europa-grotesk-sh-bold" (16pt)	Panel headers
Monospace	"MIB" (14pt)	Logs, metadata, file names
Title	"HomeVideoBold" (28pt)	Screen titles
LCD segment	"digital-7" (20pt)	Clock, timers, counters
Barcode	"code128" (28pt)	Barcode decorations
Hero	"HomeVideoBold" (44pt)	Hero branding
Industrial serif	"Redacted-Regular" (32pt)	Branding text
ASCII Art: All icons are ASCII glyphs. Scalable via pre‑computed “resolutions” (compact / expanded). No real‑time ASCII rendering engine.

3.3 Component Styles
Buttons: Inverted rectangular cutouts in header bar. Active state = single orange LED dot (#D8BF4DFF). Corner markers: + symbols. Side hatch marks (diagonal lines).

Panels: Bordered with coordinate‑style grid overlay (optional low opacity). “Bolted‑in” appearance.

Scanline effect: Subtle horizontal lines at 10% opacity over background (optional).

Navigation: Fixed tabs: Messages, Files, Contacts, Nodes, Apps, Settings, Blackbox. No deep navigation stacks – state‑based panel switching.

4. Data Models (Final Schemas)
4.1 Device Identity (SQLite)
sql
CREATE TABLE devices (
    device_id TEXT PRIMARY KEY,
    kair_number TEXT UNIQUE NOT NULL,
    public_key BLOB NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('pending','active','revoked')),
    activated_by_node TEXT,
    activation_timestamp INTEGER,
    last_seen INTEGER,
    display_name TEXT,
    created_at INTEGER
);
4.2 Contacts (Phonebook)
sql
CREATE TABLE contacts (
    knumber TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    real_phone TEXT,
    notes TEXT,
    trust_status TEXT NOT NULL CHECK(trust_status IN ('unknown','pending','trusted','blocked')),
    last_interaction INTEGER,
    avatar_ascii TEXT
);
4.3 Messages (Local cache only, node holds queue)
sql
CREATE TABLE messages (
    id TEXT PRIMARY KEY,
    sender_knumber TEXT NOT NULL,
    receiver_knumber TEXT NOT NULL,
    text TEXT,
    timestamp INTEGER NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('queued','sent','delivered','failed')),
    has_attachments INTEGER DEFAULT 0,
    encrypted_payload BLOB
);
4.4 Files (Local storage only)
sql
CREATE TABLE files (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK(type IN ('image','audio','video','binary','unknown')),
    size INTEGER NOT NULL,
    hash TEXT NOT NULL,
    local_path TEXT NOT NULL,
    encrypted INTEGER DEFAULT 1,
    created_at INTEGER NOT NULL
);
4.5 AI Memory (Local + sync to node)
sql
CREATE TABLE ai_memory (
    id TEXT PRIMARY KEY,
    memory_type TEXT NOT NULL,
    target_id TEXT,
    content TEXT NOT NULL,
    importance REAL DEFAULT 0.5,
    created_at INTEGER NOT NULL,
    synced_to_node INTEGER DEFAULT 0
);
4.6 Blackbox Snapshots
sql
CREATE TABLE blackbox_snapshots (
    id TEXT PRIMARY KEY,
    filename TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    size INTEGER NOT NULL,
    checksum TEXT NOT NULL,
    location TEXT
);
4.7 File Transfers (Node - Added for enhanced file tracking)
sql
CREATE TABLE file_transfers (
    transfer_id TEXT PRIMARY KEY,
    sender_kair TEXT NOT NULL,
    receiver_kair TEXT NOT NULL,
    total_chunks INTEGER NOT NULL,
    received_chunks INTEGER NOT NULL DEFAULT 0,
    checksum TEXT,
    status TEXT NOT NULL DEFAULT 'queued'
);
4.8 Admin Codes (Node - Rotating activation codes)
sql
CREATE TABLE admin_codes (
    code TEXT PRIMARY KEY,
    issued_at INTEGER NOT NULL,
    expires_at INTEGER NOT NULL
);
4.9 Delivery Attempts (Node - Delivery logging)
sql
CREATE TABLE delivery_attempts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    queue_id TEXT NOT NULL,
    attempted_at INTEGER NOT NULL,
    outcome TEXT NOT NULL,
    detail TEXT
);
4.10 Passcodes (Node - Device passcode storage)
sql
CREATE TABLE passcodes (
    device_id TEXT PRIMARY KEY,
    passcode TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (device_id) REFERENCES devices(device_id)
);
5. Networking & Protocols
5.1 Tailscale Integration
All devices and node join a Tailscale tailnet (e.g., kairos.ts.net).

iOS app uses Tailscale Swift SDK (or system VPN extension).

Node runs Tailscale with subnet routes if needed.

5.2 Packet Format (Unified for messages, files, calls)
json
{
  "id": "uuid",
  "type": "message | file_chunk | call_init",
  "sender_kair": "K-XXXX",
  "receiver_kair": "K-XXXX",
  "timestamp": 1700000000000,
  "encrypted_payload": "base64",
  "node_route": ["node_id"]
}
For file chunks, include chunk_index, total_chunks, checksum.

5.3 Node API (gRPC – strongly recommended)
protobuf
service KairOSNode {
  rpc ActivateDevice(ActivateRequest) returns (ActivateResponse);
  rpc SendMessage(MessagePacket) returns (SendResult);
  rpc SendFileChunk(stream FileChunk) returns (TransferStatus);
  rpc FetchQueue(FetchRequest) returns (stream QueuedItem);
  rpc GetContacts(Empty) returns (ContactList);
  rpc UpdateTrustScore(TrustUpdate) returns (Empty);
  rpc StoreAIMemory(MemoryEntry) returns (Empty);
  rpc RetrieveAIMemory(MemoryQuery) returns (MemoryEntry);
}
5.4 Communication Flow (Example: Send Message)
iOS encrypts message payload using a session key (obtained from node).

Sends encrypted packet to node over Tailnet (gRPC).

Node decrypts, validates, re‑encrypts for recipient.

Node attempts immediate delivery; if offline, stores in queue (SQLite) with exponential backoff (max 7 days).

Recipient fetches queued messages on next connection (or via optional APNs push).

5.5 Push Notifications (Optional)
Node sends silent APNs notification to wake app when messages arrive.

Requires Apple Developer Program (or use local background fetch as fallback).

6. Security & Encryption Model
6.1 Key Hierarchy
Key	Storage	Lifetime
Node Master Key	Node filesystem (600 perms)	Permanent
Session Keys	Generated per message/call/file, never stored	Ephemeral
Device Public Keys	Node database	Permanent
Device Private Key	iOS Keychain	Permanent
6.2 Encryption Flow (Node‑mediated)
Device ↔ Node: TLS over Tailnet.

Node generates AES‑256‑GCM session key for each recipient.

Node decrypts incoming, applies voice filters if needed, re‑encrypts and forwards.

Never does node store plaintext payloads after forwarding.

6.3 Blackbox Encryption
User passcode derived key using PBKDF2.

AES‑256‑GCM encryption of entire snapshot.

Node master key not used – Blackbox is self‑contained.

7. Home Node Service (Linux)
7.1 Technology
Language: Go (recommended for concurrency and easy deployment).

Database: SQLite (single file, easy backup).

Tailscale: Must be installed and authenticated.

7.2 Configuration (YAML)
yaml
tailnet: kairos.ts.net
listen_addr: :8080
db_path: /var/lib/kairios/node.db
admin_code_interval: 3600  # seconds
queue_retry_limit: 100
queue_ttl_hours: 168       # 7 days
mock_http_enabled: true    # Development convenience
mock_http_listen_addr: :8081
7.3 Identity & Activation Flow
User installs iOS app, chooses K‑number (K-XXXX format, 4 digits) and passcode.

Device sends activation request to node.

Node checks availability, creates pending device entry with status "pending_confirmation".

Node generates 4‑digit rotating admin code (displayed on node terminal).

Node administrator can approve or deny pending registrations via web UI.

If approved: node marks device as "active", sets activation_timestamp, device stores private key in Keychain.

If denied: node deletes device entry.

7.3.1 Node Confirmation Flow
Device activation request returns "pending_confirmation" state.

iOS app displays pending approval message and polls node every 5 seconds for approval status.

Node administrator views pending registrations in web UI panel.

Administrator clicks "Approve" or "Deny" for each pending registration.

On approval: node updates device status to "active", sends notification to iOS device.

iOS app receives approval notification, marks identity as activated, proceeds to home screen.

7.4 Queue Manager
Table message_queue with columns: id, receiver_kair, payload, retry_count, next_retry, created_at, expires_at.

Retry schedule: immediate, then 1m, 5m, 15m, 1h, 4h, 12h, 24h (exponential backoff).

After 7 days or 100 retries → status failed, not auto‑deleted (preserved for manual inspection).

7.5 Trust Graph
Table trust_scores: kair_number, score (0.0–1.0), interaction_count, last_updated.

Score increased on successful message/call delivery; decreased on failures or user reports.

7.6 AI Memory Store
Simple key‑value JSON store: key = user:K-number:context, value = summary blob.

ALICE Lite on iOS pushes/pulls via gRPC.

7.7 Mock HTTP Gateway (Development Convenience)
Optional HTTP REST API that mirrors gRPC functionality for development and testing.

Endpoints:
POST /activate - Device activation
POST /manual-account - Manual account creation (bypasses activation flow)
POST /messages - Send message
GET /contacts - Fetch contacts
POST /memory - Store AI memory
GET /queue?receiver_kair=... - Fetch queued messages
GET /status - Node status
POST /debug/reachability - Debug reachability control
GET /version - Returns current timestamp for auto-reload detection
GET /sounds - Returns list of available sound files (._ macOS files filtered)
GET /calls - Returns list of active voice calls
GET /filters - Returns message filtering rules
GET /settings - Returns node configuration
GET /telemetry - Returns system activity logs
GET /notes - Returns text notes
GET /media - Returns media files (._ macOS files filtered)
GET /storage - Returns disk usage statistics
GET /clock - Returns current time and display mode
GET /calendar - Returns calendar events
GET /tasks - Returns task list
POST /storage/cleanup - Deletes old telemetry events and media files
GET /pending-registrations - List pending device registrations
POST /pending-registrations/:id - Approve or deny pending registration

Purpose: Allows iOS app to work without full gRPC setup during development. Production clients should use gRPC on port 8080.

7.8 Node Control Center UI (Web Interface)
A web-based control center accessible via HTTP gateway (port 8081) for managing the Home Node.

Features:
- Tab-based navigation (Dashboard, Devices, Communications, Files, Settings)
- Help modal with comprehensive documentation organized by section (draggable)
- Sound management with category-based organization (Click Sounds, Alerts, Success, Ambient, UI Sounds, Notifications, Other, Calling Sounds)
- macOS ._ file filtering in media and sound listings
- Auto-reload mechanism to detect and apply updates
- Critical error state with color-coded alerts
- Button sound feedback with softer volume for less intrusive UX
- File browser with directory navigation and file viewing capability
- Live statistics with bar charts and line chart visualizations
- News broadcast banner for system-wide announcements
- Font optimization: MIB font used only for large text, HomeVideo for smaller text
- HomeVideoBold font uses larger sizes without additional borders (font has built-in box effect)
- Calling system with sound effects (ringtone, hangup sounds, call fail sequence, dial tones)
- Dial pad UI with hold/release logic for dial tones
- Automatic K prefix for calling input field
- Dial pad buttons add digits to calling number with K-XXXX formatting
- Pending registrations panel for node administrator approval
- Manual account creation endpoint to bypass activation flow

Calling Sound Effects:
- Ringtone: Loops until pickup, timeout, or hangup (ringtone.mp3)
- Hangup sounds: Two types - hangup_normal.mp3 for normal hangup, hangup_lostconnection.mp3 for connection loss
- Call fail sequence: Plays callfailtone.mp3 first, then callfailmessage.mp3 automatically
- Dial tones: Dial_0.mp3 through Dial_9.mp3 play while button held, stop on release
- Connection failure: Plays hangup_lostconnection.mp3 when node fails or phone cannot connect

UI Design:
- Industrial telemetry aesthetic matching iOS app (yellow/black duotone)
- Navigation tabs with active state indicators
- Collapsible sound categories to reduce clutter (expanded by default)
- Draggable pop-up help modal with sectioned documentation
- Real-time statistics display with visual charts (CPU, memory, network, queue)
- File browser with modern UI, hover effects, and directory navigation
- News banner displayed at top of dashboard for broadcasts
- Font hierarchy: HomeVideoBold (24px headers), HomeVideo (16px body), MIB (36px admin code only)
- Dial pad with grid layout (3 columns) and Digital7 font for industrial aesthetic
- Calling input field with automatic K prefix and validation

8. iOS App Implementation (SwiftUI)
8.1 Xcode Project Structure
text
KairOS/
├── App/
│   ├── KairOSApp.swift
│   ├── AppDelegate.swift (Tailscale setup)
│   └── Info.plist
├── Core/
│   ├── Networking/
│   │   ├── NodeClient.swift (gRPC client)
│   │   ├── PacketSerializer.swift
│   │   └── QueueManager.swift
│   ├── Identity/
│   │   ├── IdentityManager.swift (Keychain)
│   │   └── ActivationViewModel.swift
│   ├── Encryption/
│   │   ├── CryptoService.swift (CryptoKit)
│   │   └── KeychainWrapper.swift
│   ├── Blackbox/
│   │   ├── BlackboxExporter.swift
│   │   └── BlackboxImporter.swift
│   └── Database/
│       ├── LocalCache.swift (GRDB.swift)
│       └── Models/ (generated from SQLite)
├── UI/
│   ├── Theme/
│   │   ├── Colors.swift (hex extensions)
│   │   ├── Typography.swift (custom fonts)
│   │   └── IndustrialModifiers.swift
│   ├── Components/
│   │   ├── PanelView.swift
│   │   ├── TabBarView.swift
│   │   ├── LEDIndicator.swift
│   │   └── ScanlineOverlay.swift
│   ├── Screens/
│   │   ├── HomeView.swift (main shell)
│   │   ├── MessagesView.swift
│   │   ├── ContactsView.swift
│   │   ├── CallsView.swift
│   │   ├── NodesView.swift
│   │   ├── AppsView.swift
│   │   └── BlackboxView.swift
│   └── Navigation/
│       └── Router.swift (state‑based)
├── ALICE/
│   ├── LLM/
│   │   ├── ModelLoader.swift (Core ML)
│   │   ├── InferenceEngine.swift
│   │   └── Tokenizer.swift
│   ├── ToolDispatcher/
│   │   ├── ToolRegistry.swift
│   │   ├── SystemTools.swift
│   │   └── AppToolAdapter.swift
│   ├── Memory/
│   │   ├── ShortTermMemory.swift
│   │   └── NodeMemoryClient.swift
│   └── ALICEOrchestrator.swift
├── AppRuntime/
│   ├── Sandbox/
│   │   ├── AppContainer.swift
│   │   ├── AppLifecycle.swift
│   │   └── PermissionGate.swift
│   ├── EventBus/
│   │   ├── EventBus.swift
│   │   └── EventTypes.swift
│   ├── SDK/
│   │   ├── KairOSAPI.swift (exposed to apps)
│   │   └── ManifestLoader.swift
│   └── Apps/ (bundled)
│       ├── Notes/
│       ├── Files/
│       └── Diagnostics/
├── Resources/
│   ├── Fonts/
│   ├── Sounds/
│   └── Assets.xcassets
└── Tests/
8.2 Key Implementation Notes
Dynamic app loading: Swift cannot dynamically load code. MVP apps are compiled into main binary. Future dynamic loading would require JavaScriptCore + a bridge – not in MVP.

Tailscale SDK: Use TailscaleKit or NetworkExtension to manage VPN.

gRPC: Use grpc-swift with NIOSSL for secure channel.

State management: @StateObject + ObservableObject + singleton AppState.

8.3 iPhone Notification System
NotificationManager singleton using UserNotifications framework for registration approval notifications.

Features:
- Request notification permissions on app launch
- Send notification when registration is approved
- Send notification when registration is denied
- Send notification for incoming calls
- Badge management for notification count
- Scene phase handling to pause/resume ambient audio

Implementation:
- NotificationManager.shared.requestPermission() called on app launch
- ActivationViewModel polls for approval every 5 seconds
- On approval, NotificationManager sends notification with title and message
- Notification titles and messages configured for approval, denial, and incoming calls

8.4 Accessibility Improvements
Decorative elements hidden from VoiceOver for better screen reader experience.

Features:
- Decorative "+" marks in PanelChrome marked as .accessibilityHidden(true)
- Decorative "+" marks in TelemetryGrid marked as .accessibilityHidden(true)
- Decorative "+" marks in TabBarView marked as .accessibilityHidden(true)
- Decorative "+" marks in HomeView brand/status blocks marked as .accessibilityHidden(true)
- SwiftUI previews added for main components to test accessibility
- Dynamic type support via Font.custom(..., relativeTo: ...)

8.5 SwiftUI Previews
Development previews for main UI components to accelerate development and testing.

Features:
- PanelChrome preview with sample content
- HeaderButtonChrome preview with enabled button states
- Previews allow testing with different color schemes and dynamic type sizes
- Previews help identify layout and contrast issues early

8.6 SoundManager Scene Phase Handling
Audio lifecycle management based on app scene phase changes.

Features:
- handleScenePhase() method to pause/resume ambient audio
- On app background: stops ambient audio
- On app foreground: resumes ambient audio if it was playing
- Integrated with KairOSApp via scenePhase observation

9. ALICE AI Runtime (ALICE 2.0 → ALICE Lite)
9.0 ALICE 2.0 → ALICE Lite Distillation
ALICE 2.0 is the full‑sized, advanced LLM that serves as the source teacher. It is not deployed on iPhone due to size/compute constraints.
ALICE Lite is the distilled, quantized, Core ML‑compatible version that runs inside KairOS on the device.

Input to Codex: A folder named ALICE_2.0/ containing:

text
ALICE_2.0/
├── model_weights/          (e.g., .bin, .safetensors, or .gguf)
├── tokenizer_config.json
├── tokenizer.model
├── config.json             (architecture: layers, hidden size, etc.)
├── inference_example.py    (optional, shows usage)
├── distillation_script.py  (optional, if provided)
├── system_prompt.txt
└── tool_definitions.json   (list of tools ALICE 2.0 understands)
Codex Tasks for ALICE Lite creation:

Analyze ALICE 2.0 – read config to determine parameter count, architecture (e.g., LLaMA, Phi, Gemma).

If parameter count > 2B → must distill or prune.

If distillation_script.py exists → run it to produce a smaller student model (target size ≤ 1B).

If not, apply structured pruning (remove layers) or use knowledge distillation with a generic script (Codex can generate a basic distillation pipeline).

Quantize the resulting model to 4‑bit or 8‑bit (GPTQ, AWQ, or Core ML’s built‑in quantization).

Convert to Core ML using coremltools:

Input: tokenized text (Int64)

Output: logits (Float32)

Add MLMultiArray bindings.

Test inference on iPhone simulator / device – target response time < 2 seconds for short prompts (max 512 input tokens).

Fallback plan – if ALICE Lite still too slow/heavy:

Reduce context window to 1024 tokens.

Further prune tools (keep only essential 3‑4 tools).

Optionally allow node‑hosted ALICE 2.0 (requires GPU on node, disabled by default).

ALICE Lite capabilities (subset of ALICE 2.0):

Text generation (chat / command completion)

Tool calling (limited to system tools: send_message, list_files, search_contacts, read_file)

No image/video understanding

No multi‑turn reasoning beyond 10 exchanges (short‑term memory only)

If ALICE 2.0 folder is not provided, Codex will use a default lightweight model (e.g., Phi‑3‑mini‑4k‑instruct quantized) as ALICE Lite, but this may reduce feature alignment.

9.1 Model Loading & Inference (iOS)
Use MLModel compiled from .mlpackage.

Tokenizer: Hugging Face tokenizer converted to Swift (or use MLTextGenerator if available in iOS 18+).

Inference runs on CPU + Neural Engine (ANE) automatically via Core ML.

9.2 Tool Calling Workflow
User input → ALICE Lite analyzes intent.

If tool required, constructs tool call JSON.

Validate against app manifest permissions.

High‑impact actions (send message, delete file, initiate call) → show confirmation dialog.

Execute via ToolDispatcher, return result to ALICE Lite.

ALICE Lite generates final response.

9.3 Built‑in System Tools
Tool	Requires Confirmation	AI Access
send_message	Yes	Yes
list_files	No	Yes
read_file	No	Yes
search_contacts	No	Yes
start_call	Yes	Yes
delete_file	Yes	Yes
9.4 Memory Architecture
Short‑term: In‑memory conversation history (last 10 exchanges).

Long‑term: Stored on node as JSON summaries. ALICE Lite syncs periodically (every 5 minutes or on explicit command).

9.5 System Prompt (Example – derived from ALICE 2.0’s system_prompt.txt)
text
You are ALICE, the AI assistant for KairOS – a secure industrial communication terminal.
Current user K‑number: {{K_NUMBER}}.
Node trust score: {{TRUST_SCORE}}.
You can use tools, but must ask for confirmation before sending messages, deleting files, or making calls.
Maintain a utilitarian, no‑nonsense tone.
10. App System & SDK
10.1 App Manifest (manifest.json)
json
{
  "id": "com.kairos.notes",
  "name": "Notes",
  "version": "1.0.0",
  "entry_type": "panel",
  "permissions": ["files", "local_storage", "ai"],
  "commands": [
    {
      "name": "create_note",
      "description": "Create a new note",
      "ai_access": true,
      "parameters": { "title": "string", "content": "string" }
    }
  ],
  "ai_summary": "Manages text notes with tagging."
}
10.2 KairOS API (Exposed to Apps)
swift
protocol KairOSAPI {
    func readFile(named: String) -> Data?
    func writeFile(named: String, data: Data) throws
    func listFiles() -> [String]
    func sendMessage(to kairNumber: String, text: String, attachments: [URL]?) async throws
    func queryALICE(prompt: String) async -> String
    func publish(event: String, payload: [String: Any])
    func subscribe(to event: String, handler: @escaping ([String: Any]) -> Void)
}
10.3 Event Bus
Global events: message.received, contact.added, node.status.changed, call.incoming.

Apps subscribe via permission "events".

10.4 App UI Container
Each app is presented as a full‑screen view with tabs:

Run – main app UI.

Info – renders README.md (Markdown).

Data – shows app‑local files.

Settings – permission toggles.

11. Blackbox Format & Restore Logic
11.1 Export Process
User taps “Export Blackbox” in Blackbox view.

System serializes:

contacts.json

SQLite dump of messages (last N or all)

files/ directory (encrypted blobs)

ai_memory.json

app_states/ (per‑app JSON)

Compresses into tar.gz.

Encrypts using passcode‑derived key (AES‑256‑GCM).

Writes envelope (JSON) + encrypted payload to .kairbox file.

Shares via UIDocumentPickerViewController to Files.app.

Envelope format:
json
{
  "format_version": "1.0",
  "created_at": "2025-01-01T00:00:00Z",
  "device_id": "uuid",
  "kair_number": "K-XXXX",
  "encryption_scheme": "AES-256-GCM",
  "integrity_hash": "sha256",
  "payload": "base64_encrypted_blob"
}
11.2 Import Process
User selects .kairbox from Files app.

App reads envelope, verifies magic and integrity.

Prompts for passcode, derives key.

Decrypts and extracts to temporary directory.

Validates K‑number matches current identity (or asks to overwrite).

Replaces local database and file store.

Re‑initializes ALICE memory and syncs with node.

11.3 Failure Handling Rules (Critical)
Failed messages: Stored in local DB with status failed, never auto‑deleted. User can retry or delete manually.

Storage full: System reserves 100MB for messages + queue; stops accepting new media, shows warning.

Node offline: Local queue only, no network features. When node returns, queue flushes automatically.

Blackbox restore conflict: If K‑number differs, user must choose “replace” or “cancel”. No automatic merge.

12. Implementation Roadmap
Phase 0 – Foundation (Week 1‑2)
Xcode project, SwiftUI lifecycle, Tailscale SDK integration.

gRPC client stubs (protos).

SQLite local cache (GRDB.swift) with schemas.

Color assets, typography, industrial button styles.

Phase 1 – Node Service (Week 1‑3, parallel)
Go project, gRPC server, Tailscale setup.

Identity/activation endpoints, admin code rotation.

Encryption service (AES‑256‑GCM, session keys).

Queue manager with exponential backoff, TTL.

Trust graph + AI memory store.

Phase 2 – Core iOS Features (Week 3‑5)
Identity onboarding (K‑number, passcode, activation with admin code).

Contacts UI + phonebook.

Messaging UI (send/receive, queued indicator).

File transfer (chunked upload/download).

Node status monitor + manual sync.

Phase 3 – ALICE Integration (Week 5‑7)
Receive ALICE_2.0 folder.

Distill / quantize to ALICE Lite (≤1B parameters).

Convert to Core ML (.mlpackage).

Inference engine, tokenizer.

Tool dispatcher + confirmation UI.

Node memory client (store/retrieve).

ALICE chat interface (command palette).

Phase 4 – App Runtime & SDK (Week 7‑8)
Define KairOSAPI, permission system.

App container view (Run/Info/Data/Settings tabs).

Event bus.

Bundle example apps (Notes, Files).

Phase 5 – Blackbox & Polish (Week 9‑10)
Blackbox export/import with encryption.

Scanline overlay, UI polish.

Vibration/buzzer for notifications.

Edge‑case testing (offline, node down, storage full).

Phase 6 – Deployment & Documentation (Week 11)
User documentation (in‑app Info tabs).

Node installation script (systemd service).

Codex‑ready app SDK documentation.

13. Testing & Validation
Unit Tests
Identity generation/validation

Message queue serialization

Blackbox encode/decode roundtrip

Encryption/decryption consistency

Integration Tests
Device activation over Tailnet

Message send/receive between two simulated devices

File transfer resume after interruption

Call with voice filter

UI Tests (XCUITest)
Tab navigation

Contact import

Blackbox export flow

14. Conclusion
This final blueprint covers every base:

✅ UI visual language (hex codes, typography, industrial components)

✅ Data schemas (SQLite + JSON, updated with display_name, created_at, passcodes)

✅ Networking (Tailscale SDK, gRPC, packet format with K-XXXX format)

✅ Security (node‑mediated encryption, Blackbox)

✅ ALICE AI (distillation from ALICE 2.0 to ALICE Lite, Core ML)

✅ App runtime & SDK (sandboxed modules, event bus)

✅ Blackbox persistence (export/import, failure handling)

✅ Node confirmation flow (pending registration approval system)

✅ iPhone notification system (UserNotifications integration)

✅ Accessibility improvements (decorative elements hidden from VoiceOver)

✅ SwiftUI previews (development previews for main components)

✅ SoundManager scene phase handling (audio lifecycle management)

✅ Implementation phases with week estimates

✅ Testing strategy

v1.2 Updates:
- K-Number format simplified to K-XXXX (4 digits) for memorability
- Node confirmation flow added for registration approval
- iPhone notification system implemented
- Database schema updated with display_name, created_at, and passcodes table
- Accessibility improvements for VoiceOver support
- SwiftUI previews added for development
- SoundManager scene phase handling for audio lifecycle
- Mock API endpoints for manual-account and pending-registrations
- Dial pad button functionality with digit input

v1.3 Updates (Placeholder Removal & Implementation Completion):
- Node Mock API Server:
  - Implemented get contact by ID functionality in handleContactByID
  - Implemented end call logic in handleCallByID
  - Implemented add filter logic in handleFilters with database storage
  - Implemented delete filter logic in handleFilterByID
  - Removed placeholder comment for media cleanup
  - Added force refresh parameter to admin code endpoint (/mock/v1/admin-code?force=true)
  - Enhanced contact deletion with existence check and proper error handling
  - Enhanced account creation error messages with specific requirements

- Contacts Service:
  - Added Get method for retrieving individual contacts by K-Number
  - All placeholder "would go here" comments removed

- Database Migration:
  - Enhanced K-Number migration to handle K-XXXX-XXXX format (8 digits)
  - Added check to prevent re-migrating already migrated contacts
  - Node device auto-creation with K-1919 (Home Node) on migration

- iOS App - LoginView:
  - Implemented actual passcode validation logic
  - Removed TODO comment for login implementation

- iOS App - TasksView:
  - Implemented task details sheet with full task information display
  - Added state variables for task selection and details view
  - Implemented fetchTasksFromNode API call to /mock/v1/tasks
  - Implemented createTaskOnNode API call with proper JSON body
  - Added TasksResponse struct for API deserialization
  - Made Task struct Codable for JSON handling
  - Removed all TODO comments

- iOS App - MediaView:
  - Implemented media preview sheet with file details
  - Added state variables for media selection and preview
  - Implemented uploadMedia with multipart/form-data upload to /mock/v1/files/upload
  - Implemented fetchMediaFromNode API call to /mock/v1/files/browse
  - Implemented deleteMediaOnNode API call with DELETE method
  - Added MediaResponse struct for API deserialization
  - Made MediaItem struct Codable for JSON handling
  - Added formatDate helper function
  - Removed all TODO comments

- iOS App - CalendarView:
  - Implemented event details sheet with full event information display
  - Added state variables for event selection and details view
  - Implemented fetchEventsFromNode API call to /mock/v1/calendar
  - Implemented createEventOnNode API call with proper JSON body
  - Added CalendarResponse struct for API deserialization
  - Made CalendarEvent struct Codable for JSON handling
  - Removed all TODO comments

- iOS App - NotesView:
  - Implemented note details sheet with full note information display
  - Added state variables for note selection and details view
  - Implemented fetchNotesFromNode API call to /mock/v1/notes
  - Implemented createNoteOnNode API call with proper JSON body
  - Added NotesResponse struct for API deserialization
  - Made Note struct Codable for JSON handling
  - Removed all TODO comments

- iOS App - TelemetryView:
  - Implemented fetchTelemetryFromNode API call to /mock/v1/telemetry
  - Added TelemetryResponse struct for API deserialization
  - Made TelemetryEvent struct Codable for JSON handling
  - Removed TODO comment

All temporary placeholders and TODO comments have been replaced with fully functional implementations. All iOS views now have real API integration with the node backend, proper error handling, and complete user interfaces for viewing and managing data.
