# Home Node Specification

## Runtime

- Language: Go
- Database: SQLite
- Network: Tailscale Tailnet
- Operator targets:
  - macOS test node: local foreground process
  - Linux production node: systemd-managed daemon
  - Windows: portable executable

## Portability Requirements

**Critical:** The Node must be fully portable and work independently on any system (Mac, Linux, Windows).

### Key Requirements:
- **Self-contained operation:** Node works inside its folder regardless of location
- **Cross-platform support:** Must run on macOS, Linux, and Windows without modification
- **Automatic detection:** All network configuration and Tailscale detection must be automatic
- **No hardcoded paths:** All paths must be relative to the working directory
- **Zero configuration required:** Node should work out of the box with sensible defaults

### Implementation:
- Database path: `./var/kairos-node.db` (relative to working directory)
- Master key path: `./var/node-master.key` (relative to working directory)
- Network auto-detection: Automatically detects local IP address
- Tailscale auto-detection: Automatically detects Tailscale IP if available
- Config auto-detection: If config file missing, uses auto-detected values
- No platform-specific defaults: Same defaults across all platforms

### Auto-Detection Features:
- Local IP address detection via network interface enumeration
- Tailscale IP detection via `tailscale status --json` command
- Graceful fallback to local network if Tailscale unavailable
- HTTP gateway automatically binds to detected IP
- iOS app auto-discovers Node endpoint on local network

## Core Modules

- `config`: YAML config loading and defaults
- `db`: SQLite opening and migrations
- `identity`: K-number validation and device registration
- `activation`: rotating admin code issuance and device activation
- `crypto`: AES-256-GCM session encryption helpers
- `queue`: durable queued delivery with exponential retry
- `contacts`: trusted phonebook service
- `trust`: delivery-derived trust score tracking
- `memory`: long-term AI summary storage
- `transport`: request/response service surface to be bridged to gRPC
- `mockapi`: macOS-first JSON gateway for app integration while Swift gRPC remains in progress
- `apns`: optional push wake adapter

## Operational Behavior

- Node owns device activation and device registry state.
- Node never auto-deletes failed messages; it moves them to failed state for manual inspection.
- Node retries queued messages using the locked schedule and expires them to failed after TTL/retry cap.
- Node stores no plaintext payloads after routing or queue persistence.

## Storage

- Default macOS DB path: `./var/kairos-node.db`
- Default Linux DB path: `/var/lib/kairos/node.db`
- Master key path must be operator-configurable and `0600`.
- Default macOS mock HTTP listen address: `:8081`

## Delivery Rules

- Immediate send attempt on receipt
- Backoff sequence: `0m, 1m, 5m, 15m, 1h, 4h, 12h, 24h`
- Hard limits:
  - retry cap: 100
  - TTL: 168 hours

## Transport Note

The codebase defines the canonical protobuf contract in `proto/`. The node now exposes both:

- canonical gRPC on `listen_addr`
- a development mock HTTP gateway on `mock_http_listen_addr` for simulator-first app integration

Both adapters share the same underlying services and SQLite state.

## Control Center Features

**Critical:** The Node must provide a web-based control center for complete management of the KairOS system.

### Web-Based Control Center
- **Industrial UI:** Same yellow/black industrial telemetry design as iOS KairOS
- **Real-time Monitoring:** Live status of Node, devices, queue, and network
- **Settings Management:** All Node settings configurable via web UI
- **Sound Management:** Play and manage system sounds
- **Device Management:** View, activate, deactivate, and manage connected devices
- **Queue Management:** View, retry, and manage message queue
- **Contact Management:** Add, edit, and manage trusted contacts
- **Trust Management:** View and adjust trust scores for contacts
- **Memory Management:** View and manage AI memory entries
- **Admin Code Management:** Generate and display current admin codes
- **Tailscale Status:** Monitor and display Tailscale connection status

### Sound System
- **System Sounds:** All sounds from iOS KairOS available on Node
- **Sound Categories:**
  - User interactions (send message, receive message)
  - System events (activation, connection, error)
  - UI feedback (key presses, alerts, confirmations)
  - File operations (upload, download, success, failure)
- **Sound API:** REST API for playing sounds on-demand
- **Sound Storage:** Sounds stored in `./sounds/` directory relative to Node folder
- **Sound Auto-Discovery:** Automatically loads all .mp3 and .wav files from sounds directory

### Settings Management
- **Configurable Settings:**
  - Network settings (listen address, ports)
  - Tailscale settings (enabled, tailnet name)
  - Queue settings (retry limit, TTL)
  - Activation settings (admin code interval)
  - Sound settings (volume, enabled/disabled)
  - Security settings (encryption options)
- **Settings API:** REST API for reading and updating settings
- **Settings Persistence:** Settings saved to config.yaml
- **Hot Reload:** Settings changes take effect immediately (no restart required)

### Real-Time Monitoring
- **Node Status:** CPU, memory, network usage
- **Device Status:** Connected devices, activation status, last seen
- **Queue Status:** Pending messages, failed messages, retry counts
- **Network Status:** Tailscale connection, local network, bandwidth
- **Database Status:** Database size, last migration, health check
- **Live Updates:** WebSocket or SSE for real-time updates

### Device Management
- **Device List:** View all registered devices
- **Device Details:** K-number, activation time, last activity
- **Device Actions:** Activate, deactivate, remove device
- **Device Logs:** View device activity logs
- **Device Statistics:** Message count, success rate, error rate

### Queue Management
- **Queue View:** View all queued messages
- **Queue Actions:** Retry message, delete message, clear failed messages
- **Queue Statistics:** Success rate, failure rate, average delivery time
- **Queue Configuration:** Adjust retry schedule, TTL, retry limit

### Contact Management
- **Contact List:** View all trusted contacts
- **Contact Details:** K-number, display name, trust score, notes
- **Contact Actions:** Add, edit, remove contact
- **Trust Management:** Adjust trust scores for contacts
- **Contact History:** View interaction history with contact

### API Endpoints
- `GET /` - Control center web UI
- `GET /api/status` - Node status
- `GET /api/settings` - Get settings
- `PUT /api/settings` - Update settings
- `GET /api/devices` - List devices
- `POST /api/devices/:id/activate` - Activate device
- `GET /api/queue` - List queued messages
- `POST /api/queue/:id/retry` - Retry message
- `GET /api/contacts` - List contacts
- `POST /api/contacts` - Add contact
- `GET /api/sounds` - List sounds
- `POST /api/sounds/:id/play` - Play sound
- `GET /api/admin-code` - Get current admin code
