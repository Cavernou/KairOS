# Next Session Handoff

## What Exists Now

- architecture and subsystem docs in `docs/`
- shared protobuf contract in `proto/kairos_node.proto`
- Go node core scaffold in `node/`
- SwiftUI client scaffold in `ios/KairOS/`

## Required Tooling Before Full Validation

- Go 1.22+
- `protoc`
- Go protobuf plugins:
  - `protoc-gen-go`
  - `protoc-gen-go-grpc`
- Swift protobuf generation toolchain as chosen for the iOS client
- Full Xcode installation or XcodeGen installed alongside Xcode

## Recommended Next Commands

### 1. Install and verify Go

`go version`

### 2. Generate protobuf bindings

From the workspace root:

`protoc --go_out=node --go-grpc_out=node proto/kairos_node.proto`

Generate Swift bindings into the iOS client using the selected Swift protobuf/grpc toolchain.

### 3. Build the node

From `node/`:

`go mod tidy`

`go test ./...`

`go run ./cmd/kairos-node -config ./config.example.yaml`

### 4. Generate/open the iOS project

From `ios/KairOS/`:

- if using XcodeGen: `xcodegen generate`
- then open the generated project in Xcode

### 5. Replace transport stubs

- attach the generated gRPC adapter to `internal/transport`
- replace the temporary `NodeClient` stub with live gRPC calls
- wire local cache from preview arrays to GRDB-backed persistence

## First Integration Goal

Complete one end-to-end slice:

- iOS onboarding
- node activation
- queued message send
- reconnect fetch
- visible queued/failed state in the iOS shell
