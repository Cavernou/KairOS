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
- ✅ Automatic K-XXXX format for calling input field
- ✅ Registration flow with help page and validation
- ✅ Login page for already registered users
- ✅ K-Number format simplified to K-XXXX (4 digits)
- ✅ Display name field added to registration
- ✅ Avatar image limitations (max 5MB, 2048x2048)
- ✅ Colors updated to exact hex codes from blueprint
- ✅ Non-functional tooltips removed
- ✅ iPhone notification system with UserNotifications
- ✅ Notification permission request on app launch
- ✅ Polling mechanism for registration approval status
- ✅ Pending approval message display in activation screen
- ✅ Notification sent when registration is approved

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
- ✅ K-XXXX format for calling input field
- ✅ Manual account creator to bypass activation flow
- ✅ API endpoint for manual account creation (/mock/v1/manual-account)
- ✅ Node confirmation flow for registration approval
- ✅ Pending registrations panel in web UI
- ✅ API endpoints for pending registration management
- ✅ Database migration for K-Number format conversion
- ✅ Dial pad buttons add digits to calling number

### Testing
- **Go Tests**: Run with `cd node && go test ./...`
- **iOS Tests**: Run with `cd ios/KairOS && xcodebuild test -scheme KairOS -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.2' -only-testing:KairOSTests`

Note: iOS tests currently fail due to missing mock server infrastructure. The build succeeds and tests execute, but network calls fail since no actual node is running during tests.

## Recent Updates

### v1.0.3 (April 2026)
- Fixed node dialtone buttons to add digits to calling number instead of just playing sound
- Added addDialDigit() function to format digits as K-XXXX when added
- Added database migration to convert old K-XXXX-XXXX-XXXX-XXXX format to K-XXXX
- Implemented node confirmation flow for registration approval
- Added GET /mock/v1/pending-registrations endpoint to list pending registrations
- Added POST /mock/v1/pending-registrations/:id endpoint to approve/deny registrations
- Added PENDING REGISTRATIONS panel to node web UI with approve/deny buttons
- Modified activation endpoint to return "pending_confirmation" state instead of immediately activating
- Added iOS polling mechanism to check for registration approval every 5 seconds
- Implemented iPhone notification system with UserNotifications
- Added NotificationManager for registration approval/denial notifications
- Added notification permission request on app launch
- iOS app automatically sends notification when registration is approved
- Added pending approval message display in iOS ActivationTerminalView
- Updated API documentation with pending registration endpoints
- iOS app UI already matches node style (fonts, colors, layout)

### v1.0.2 (April 2026)
- Added login page for already registered users
- Added manual account creator in node web UI to bypass activation flow
- Simplified K-Number format to K-XXXX (4 digits) for easier memorability
- Added display name field to registration (2-32 characters)
- Added help page to replace Quick Start Guide
- Added avatar image limitations (max 5MB, max 2048x2048 dimensions)
- Updated iOS colors to exact hex codes from blueprint
- Removed non-functional ? tooltips from UI
- Fixed activation freeze issue with loading state
- Fixed SoundManager ObservableObject error
- Fixed dial pad 0 button centering
- Updated node web UI K-Number format to K-XXXX
- Added /mock/v1/manual-account API endpoint for manual account creation
- Updated API documentation

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
