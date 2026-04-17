# KairOS

KairOS is a greenfield secure communications platform composed of:

- `node/`: the Home Node daemon in Go
- `ios/`: the SwiftUI iOS client
- `proto/`: shared transport contracts
- `docs/`: build specifications and implementation notes
- `design/`: visual system guidance

This workspace was initialized from the locked KairOS blueprint and is structured so the node can be tested on macOS first and deployed to Linux as the production target.

## Current Status

### iOS App
- ✅ Build successful (Xcode 16.2, iOS 18.2)
- ✅ Tests build and run (45 tests, 23 failures due to missing mock server infrastructure)
- ✅ Sound system implemented with global SoundManager
- ✅ Activation page UI fixed with avatar upload
- ✅ Industrial theme with yellow/black design
- ✅ HTTP-based NodeClient (gRPC removed due to dependency issues)

### Node Service
- ✅ Go tests passing
- ✅ SQLite database with complete schemas
- ✅ gRPC server implementation
- ✅ Queue management with exponential backoff

### Testing
- **Go Tests**: Run with `cd node && go test ./...`
- **iOS Tests**: Run with `cd ios/KairOS && xcodebuild test -scheme KairOS -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.2' -only-testing:KairOSTests`

Note: iOS tests currently fail due to missing mock server infrastructure. The build succeeds and tests execute, but network calls fail since no actual node is running during tests.
