# Changelog

All notable changes to KairOS will be documented in this file.

## [1.0.1] - April 2026

### Added
- Calling sound effects to node and iOS app:
  - Ringtone with loop until pickup/timeout/hangup
  - Hangup sounds (normal and lost connection)
  - Call fail sequence (tone followed by message)
  - Dial tones (Dial_0 through Dial_9) with hold/release logic
- Dial pad UI to iOS app with 3-column grid layout
- Automatic K prefix to calling input fields (node web UI and iOS app)
- Quick Start Guide to iOS registration flow
- Field validation to iOS registration (K-NUMBER, ADMIN CODE, etc.)
- Better error messages with specific guidance
- File transfer database tracking functionality

### Changed
- Improved registration flow with step-by-step guide and helpful tips
- Enhanced help text for all registration fields
- Made avatar upload optional with clearer labeling
- Updated auto-reload mechanism to only trigger on node restart/rebuild
- Fixed sound viewer to preserve category state across reloads
- Fixed file viewer to properly clear content when opening new files
- Fixed file browser path handling to prevent duplicate slashes
- Removed all TODO comments from backend code

### Fixed
- Sound viewer bug where categories reset when reloading sounds
- File viewer bug where content from previous files bled into new file views
- File browser path construction issue with duplicate slashes
- Auto-reload triggering on file changes instead of large updates

## [1.0.0] - Initial Release

### Added
- Complete KairOS secure communications platform
- iOS app with industrial UI and yellow/black design
- Home Node service with Go and gRPC
- SQLite database with complete schemas
- Queue management with exponential backoff
- ALICE AI integration
- Blackbox backup/restore system
- App runtime with SDK and sandboxing
