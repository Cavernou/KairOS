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

### Core Modules

- `config`: YAML config loading and defaults
- `db`: SQLite opening and migrations
- `identity`: K-number validation and device registration
- `activation`: rotating admin code issuance and device activation
- `crypto`: AES-256-GCM session encryption helpers
- `queue`: durable queued delivery with exponential retry
- `taskqueue`: separate task queue for system operations (sync, backup, maintenance)
- `contacts`: trusted phonebook service
- `trust`: delivery-derived trust score tracking
- `memory`: long-term AI summary storage
- `telemetry`: activity logging and event timeline
- `notes`: structured text notes system
- `media`: image, audio, video handling with safeguards
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

### Calling Management
- **Call List:** View all active calls
- **Call Details:** K-number, status, duration, audio quality
- **Call Actions:** Initiate call, end call, mute/unmute
- **Call History:** View past calls with timestamps
- **Call Statistics:** Success rate, average duration, error rate

### Filtering Management
- **Filter List:** View all content filters
- **Filter Details:** Keyword, type (block/allow), scope
- **Filter Actions:** Add filter, remove filter, enable/disable
- **Filter Types:** Keyword blocking, content filtering, spam detection
- **Filter Statistics:** Filtered messages, blocked count, false positives

### Telemetry & Activity Logging
- **Activity Log:** Chronological feed of all system events
- **Event Types:** Message sent/received, device connected/disconnected, file transfer, call started/ended
- **Activity Analytics:** Time-of-day activity patterns, device usage statistics
- **Event Timeline:** Visual timeline of system events
- **Log Storage:** Activity logs stored in database with retention policy
- **Log Export:** Export activity logs for analysis
- **Real-time Updates:** Live activity feed in control center

### Notes System
- **Note List:** View all structured text notes
- **Note Details:** Title, content, created/modified timestamps, tags
- **Note Actions:** Create, edit, delete, search notes
- **Note Sync:** Notes synced across devices via Node
- **Note Search:** Search across notes by content or tags
- **Note Categories:** Organize notes by tags or folders

### Media Handling
- **Image Support:** View and send images with size safeguards
- **Audio Support:** Play and send audio messages
- **Video Support:** Play and send videos (constrained controls)
- **Media Safeguards:** File size limits, format validation, processing power checks
- **Unknown File Handling:** Detect unsupported formats, display warnings, prevent crashes
- **Media Storage:** Media files stored with encryption and deduplication
- **Media Compression:** Automatic compression for large files
- **Media Thumbnails:** Generate thumbnails for images/videos

### File Conflict Resolution
- **Conflict Detection:** Detect when same file modified on multiple devices
- **Conflict Resolution Strategies:** Last write wins, manual resolution, keep both
- **Conflict UI:** Display conflicts in control center for manual resolution
- **Conflict History:** Track conflict resolution history
- **Automatic Resolution:** Configurable automatic conflict resolution policy

### Storage Management
- **Storage Reserves:** Reserve space for critical operations (messages, queue)
- **Storage Monitoring:** Monitor disk usage and warn when approaching limits
- **Storage Full Handling:** Stop accepting new media when storage full, show warning
- **Storage Cleanup:** Automatic cleanup of old/unused files
- **Storage Quotas:** Per-device storage quotas
- **Storage Statistics:** View storage usage by type (messages, files, media, notes)

### Clock System
- **System Clock:** Digital clock display in control center
- **Clock Modes:** 12-hour, 24-hour, UTC
- **Time Synchronization:** Sync with NTP servers
- **Clock Drift Handling:** Prevent system freeze due to clock drift
- **Timestamp Display:** Show timestamps for all events
- **Timezone Support:** Display times in local timezone

### Calendar & Tasks
- **Calendar View:** View calendar with events
- **Event Types:** Tasks, reminders, meetings, system events
- **Event Details:** Title, description, start time, end time, location, attendees
- **Event Actions:** Create, edit, delete events
- **Task Management:** Create tasks with due dates, priorities, completion status
- **Task Categories:** Organize tasks by tags or categories
- **Task Reminders:** Automatic reminders for upcoming tasks
- **Task Sync:** Tasks synced across devices via Node
- **Calendar Export:** Export calendar as iCal format

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
- `DELETE /api/contacts/:id` - Delete contact
- `GET /api/sounds` - List sounds
- `POST /api/sounds/:id/play` - Play sound
- `GET /api/admin-code` - Get current admin code
- `GET /api/calls` - List active calls
- `POST /api/calls` - Initiate call
- `DELETE /api/calls/:id` - End call
- `GET /api/filters` - List filters
- `POST /api/filters` - Add filter
- `DELETE /api/filters/:id` - Delete filter
- `GET /api/telemetry` - Get activity log
- `GET /api/telemetry/export` - Export activity log
- `GET /api/notes` - List notes
- `POST /api/notes` - Create note
- `PUT /api/notes/:id` - Update note
- `DELETE /api/notes/:id` - Delete note
- `GET /api/notes/search` - Search notes
- `GET /api/media` - List media files
- `POST /api/media` - Upload media
- `DELETE /api/media/:id` - Delete media
- `GET /api/storage` - Get storage statistics
- `GET /api/conflicts` - List file conflicts
- `POST /api/conflicts/:id/resolve` - Resolve conflict
- `GET /api/clock` - Get system time
- `PUT /api/clock/settings` - Update clock settings
- `GET /api/calendar` - Get calendar events
- `POST /api/calendar` - Create event
- `PUT /api/calendar/:id` - Update event
- `DELETE /api/calendar/:id` - Delete event
- `GET /api/calendar/export` - Export calendar as iCal
- `GET /api/tasks` - List tasks
- `POST /api/tasks` - Create task
- `PUT /api/tasks/:id` - Update task
- `DELETE /api/tasks/:id` - Delete task
