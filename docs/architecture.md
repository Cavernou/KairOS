# KairOS Architecture

## Overview

KairOS is a node-centric secure communications system. The iOS app presents an industrial terminal interface and delegates identity authority, routing, trust, message queueing, and long-term AI memory to a trusted Home Node connected over Tailnet.

## Major Components

- iOS app
  - SwiftUI shell
  - local cache via SQLite/GRDB
  - Keychain-backed device identity
  - ALICE Lite runtime
  - Blackbox export/import
- Home Node
  - Go daemon
  - SQLite persistence
  - activation and identity authority
  - encryption and routing
  - queue manager
  - trust graph
  - AI memory store
- Shared contract
  - protobuf/gRPC transport
  - unified packet envelope
  - shared status/error semantics

## Trust Boundaries

- The node is trusted for key orchestration, queueing, trust scoring, and long-term memory.
- The iOS device is trusted for private key custody in Keychain and local cache confidentiality.
- Tailnet provides private network reachability; application-level crypto and device activation remain required.

## Initial Delivery Order

1. Documentation and shared contract
2. Node core services and SQLite schema
3. iOS onboarding, identity, and messaging shell
4. File transfer and Blackbox
5. ALICE Lite and bundled app runtime
