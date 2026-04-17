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
