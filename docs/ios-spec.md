# iOS App Specification

## App Role

The iOS client is a stateful session shell but a stateless product surface: it keeps local cache and device credentials, but source-of-truth authority remains on the node and durable backup/restore is handled by Blackbox.

## Shell

Fixed tabs:

- Messages
- Files
- Contacts
- Nodes
- Apps
- Settings
- Blackbox

The shell uses state-based switching rather than deep push navigation.

## Core Services

- `IdentityManager`: K-number, activation state, Keychain-backed keys
- `NodeClient`: node transport client aligned to `proto/kairos_node.proto`, currently speaking to the macOS mock HTTP gateway with graceful local fallback
- `LocalCache`: GRDB-backed local message/file/memory cache
- `CryptoService`: client-side AES-GCM helpers for local export/import and payload handling
- `BlackboxExporter` / `BlackboxImporter`: backup/restore

## UX Rules

- Industrial telemetry visuals are mandatory
- Failed messages remain visible until manual user action
- Offline state must remain legible and actionable
- High-impact ALICE tool actions must prompt for confirmation
- The shell must detect orientation and re-adjust panel composition for portrait versus landscape instead of merely scaling the same layout.
- Settings must expose the test-node host and port so simulator/device runs can be re-pointed without recompiling.
