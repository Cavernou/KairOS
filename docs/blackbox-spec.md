# Blackbox Specification

## Format

Blackbox exports use `.kairbox` and contain:

- JSON envelope
- encrypted compressed payload
- integrity hash

## Payload Contents

- contacts export
- message cache dump
- encrypted file blobs
- AI memory cache
- per-app state

## Crypto

- PBKDF2-derived key from user passcode
- AES-256-GCM payload encryption
- SHA-256 integrity hash in envelope metadata

## Conflict Handling

- If K-number matches current identity: replace local cache
- If K-number differs: show replace-or-cancel prompt
- No automatic merge behavior
