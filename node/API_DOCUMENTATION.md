# KairOS Node API Documentation

This document describes all API endpoints available in the KairOS Node mock HTTP gateway (port 8081).

## Real System Endpoints (No Mocking)

### GET /mock/v1/metrics
Returns real system metrics from the node.

**Response:**
```json
{
  "cpu_usage": 0.0,           // CPU usage percentage (calculated from runtime.MemStats)
  "memory_usage": 14.4,      // Memory usage percentage
  "memory_alloc": 2634552,   // Allocated memory in bytes
  "memory_sys": 18286856,     // System memory in bytes
  "network_traffic": 0.0,    // Network traffic (MB/s) - placeholder for future implementation
  "queue_count": 0,           // Message queue count (from database)
  "goroutines": 13,           // Number of active goroutines
  "load_average": [0.13],     // System load average
  "uptime": 6.431042834       // Uptime in seconds
}
```

**Implementation:** Uses Go's `runtime.ReadMemStats()` to get real memory metrics, `runtime.NumGoroutine()` for goroutine count, and `time.Since(startTime)` for uptime calculation.

### GET /mock/v1/news
Returns the latest non-expired news broadcast from the node.

**Response:**
```json
{
  "message": "KairOS v1.1.0 released with real system metrics, node-based broadcasts, and improved file browser",
  "timestamp": 1776468228,
  "priority": "high",
  "expires_at": 1779060228
}
```

### POST /mock/v1/news
Creates a new news broadcast on the node.

**Request Body:**
```json
{
  "message": "Your broadcast message",
  "priority": "high",
  "expires_at": 1779060228  // Optional, defaults to 24 hours
}
```

**Implementation:** Stores broadcasts in memory in the Server struct, automatically expires old broadcasts.

## File Browser Endpoints

### GET /mock/v1/files/browse?path=<directory>
Lists files and directories in the specified path.

**Parameters:**
- `path` - Directory path to browse (sandboxed to node directory)

**Response:**
```json
{
  "path": ".",
  "files": [
    {
      "is_dir": true,
      "name": "cmd",
      "size": 262144,
      "modified": 1776401016
    },
    {
      "is_dir": false,
      "name": "config.yaml",
      "size": 344,
      "modified": 1776464645
    }
  ]
}
```

**Security Features:**
- Path traversal protection (cannot escape node directory)
- Hidden files filtered (files starting with .)
- macOS ._ files filtered

### GET /mock/v1/files/view?path=<filepath>
Views the contents of a text file.

**Parameters:**
- `path` - File path to view

**Response:** Plain text file content

**Security Features:**
- Path traversal protection
- Binary file detection (rejects files with null bytes)
- File size limit (1MB maximum)

## Node Status Endpoints

### GET /mock/v1/status
Returns the current status of the node.

**Response:**
```json
{
  "is_reachable": true,
  "tailnet": "kairos.ts.net",
  "last_sync": 1776468247489,
  "tailscale_connected": true,
  "devices": null
}
```

### GET /mock/v1/version
Returns the node version information.

**Response:**
```json
{
  "version": "1.0.0",
  "build": "dev"
}
```

## Device Management Endpoints

### GET /mock/v1/devices
Returns list of registered devices.

**Response:**
```json
{
  "devices": []
}
```

### POST /mock/v1/activate
Activates a device using an admin code.

**Request Body:**
```json
{
  "admin_code": "XXXX-XXXX-XXXX-XXXX",
  "device_name": "My Device"
}
```

## Communication Endpoints

### GET /mock/v1/contacts
Returns list of contacts.

**Response:**
```json
{
  "contacts": [
    {
      "id": "K-2000-0002",
      "display_name": "Field Contact",
      "notes": "Recovered from macOS test node",
      "trust_status": "pending",
      "last_interaction": 1776466428000,
      "avatar_ascii": "<:>"
    }
  ]
}
```

### POST /mock/v1/contacts
Creates a new contact.

### DELETE /mock/v1/contacts/<id>
Deletes a contact by ID.

### GET /mock/v1/messages
Returns list of messages.

### POST /mock/v1/messages
Sends a message to a contact.

### GET /mock/v1/queue
Returns message queue status.

## Media Endpoints

### GET /mock/v1/sounds
Returns list of available sound files.

**Response:**
```json
[
  {
    "name": "AccessGranted",
    "path": "AccessGranted.mp3"
  },
  {
    "name": "DISAPPOINTING_FAILURE",
    "path": "DISAPPOINTING_FAILURE.mp3"
  }
]
```

**Filtering:** macOS ._ files automatically filtered from results.

### GET /mock/v1/media
Returns list of media files.

**Response:**
```json
{
  "media": []
}
```

**Filtering:** macOS ._ files automatically filtered from results.

## Storage Endpoints

### GET /mock/v1/storage
Returns storage statistics.

**Response:**
```json
{
  "files": "2.00 GB",
  "free": "76.64 GB",
  "media": "0.00 GB",
  "messages": "0.50 GB",
  "total": "3725.93 GB",
  "used": "3649.29 GB"
}
```

### POST /mock/v1/storage/cleanup
Cleans up old telemetry events and media files.

## Telemetry Endpoints

### GET /mock/v1/telemetry
Returns telemetry events.

**Response:**
```json
{
  "events": null
}
```

## Admin Code Endpoints

### GET /mock/v1/admin-code
Returns the current admin code.

**Response:**
```json
{
  "code": "XXXX-XXXX-XXXX-XXXX",
  "expires_at": 1776472000
}
```

## Calendar Endpoints

### GET /mock/v1/calendar
Returns calendar events.

### GET /mock/v1/calendar/<id>
Returns a specific calendar event.

### POST /mock/v1/calendar
Creates a new calendar event.

### DELETE /mock/v1/calendar/<id>
Deletes a calendar event.

### GET /mock/v1/calendar/export
Exports calendar events.

## Task Endpoints

### GET /mock/v1/tasks
Returns task list.

### GET /mock/v1/tasks/<id>
Returns a specific task.

## Clock Endpoints

### GET /mock/v1/clock
Returns clock information.

### GET /mock/v1/clock/settings
Returns clock settings.

## Summary

The KairOS Node API provides:
- **Real system metrics** using Go's runtime package
- **Node-based news broadcasts** with in-memory storage and expiration
- **Secure file browser** with path traversal protection and binary detection
- **Device management** with admin code activation
- **Contact management** with trust status tracking
- **Message queue** with retry logic
- **Sound and media management** with macOS ._ file filtering
- **Storage management** with cleanup capabilities
- **Telemetry collection** for system monitoring

All file operations are sandboxed to the node directory for security.
