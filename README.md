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
- ✅ Calling system with sound effects (ringtone, hangup sounds, call fail sequence, dial tones)
- ✅ Dial pad UI with hold/release logic for dial tones
- ✅ Automatic K prefix for calling input field
- ✅ Registration flow improved with Quick Start Guide and validation

### Node Service
- ✅ Go tests passing
- ✅ SQLite database with complete schemas
- ✅ gRPC server implementation
- ✅ Queue management with exponential backoff
- ✅ Calling sound effects (ringtone, hangup sounds, call fail sequence, dial tones)
- ✅ File transfer functionality with database tracking
- ✅ Auto-reload mechanism to only trigger on node restart/rebuild
- ✅ Sound viewer with category state preservation
- ✅ File viewer with proper content clearing
- ✅ File browser with improved path handling

### Testing
- **Go Tests**: Run with `cd node && go test ./...`
- **iOS Tests**: Run with `cd ios/KairOS && xcodebuild test -scheme KairOS -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.2' -only-testing:KairOSTests`

Note: iOS tests currently fail due to missing mock server infrastructure. The build succeeds and tests execute, but network calls fail since no actual node is running during tests.

## Recent Updates

### v1.0.1 (April 2026)
- Added calling sound effects to both node and iOS app
- Implemented dial pad UI with hold/release logic
- Added automatic K prefix to calling input fields
- Improved registration flow with Quick Start Guide and validation
- Fixed auto-reload to only trigger on node restart/rebuild
- Fixed sound viewer category state preservation
- Fixed file viewer content clearing
- Fixed file browser path handling
- Removed all TODO comments from backend code
