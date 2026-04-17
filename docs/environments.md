# Environments

## macOS Test Node

Purpose:

- local development
- protocol validation
- iOS simulator/device integration
- queue and activation testing

Behavior:

- run as a foreground process
- use local writable paths inside the workspace or user home directory
- enable the mock HTTP gateway on `:8081` by default for simulator-first integration
- surface the rotating admin code through the local node terminal and the mock test endpoint
- no platform-specific feature flags in core logic

## Linux Production Node

Purpose:

- long-running trusted home node
- production persistence and routing

Behavior:

- run under systemd
- use `/var/lib/kairos` style paths
- disable the mock HTTP gateway unless explicitly needed for diagnostics
- enforce file ownership and `0600` key permissions
- assume Tailscale is installed and authenticated before service start

## Shared Rule

The node core must behave identically on macOS and Linux. Only packaging, startup wrappers, and default filesystem paths may vary by platform.
