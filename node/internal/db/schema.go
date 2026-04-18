package db

const schema = `
CREATE TABLE IF NOT EXISTS devices (
    device_id TEXT PRIMARY KEY,
    kair_number TEXT UNIQUE NOT NULL,
    public_key BLOB NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('pending','active','revoked')),
    activated_by_node TEXT,
    activation_timestamp INTEGER,
    last_seen INTEGER,
    display_name TEXT,
    created_at INTEGER
);

CREATE TABLE IF NOT EXISTS contacts (
    knumber TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    real_phone TEXT,
    notes TEXT,
    trust_status TEXT NOT NULL CHECK(trust_status IN ('unknown','pending','trusted','blocked')),
    last_interaction INTEGER,
    avatar_ascii TEXT
);

CREATE TABLE IF NOT EXISTS message_queue (
    id TEXT PRIMARY KEY,
    receiver_kair TEXT NOT NULL,
    payload BLOB NOT NULL,
    retry_count INTEGER NOT NULL DEFAULT 0,
    next_retry INTEGER NOT NULL,
    created_at INTEGER NOT NULL,
    expires_at INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'queued' CHECK(status IN ('queued','delivered','failed'))
);

CREATE TABLE IF NOT EXISTS trust_scores (
    kair_number TEXT PRIMARY KEY,
    score REAL NOT NULL,
    interaction_count INTEGER NOT NULL DEFAULT 0,
    last_updated INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS ai_memory (
    id TEXT PRIMARY KEY,
    memory_type TEXT NOT NULL,
    target_id TEXT,
    content TEXT NOT NULL,
    importance REAL DEFAULT 0.5,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS file_transfers (
    transfer_id TEXT PRIMARY KEY,
    sender_kair TEXT NOT NULL,
    receiver_kair TEXT NOT NULL,
    total_chunks INTEGER NOT NULL,
    received_chunks INTEGER NOT NULL DEFAULT 0,
    checksum TEXT,
    status TEXT NOT NULL DEFAULT 'queued'
);

CREATE TABLE IF NOT EXISTS admin_codes (
    code TEXT PRIMARY KEY,
    issued_at INTEGER NOT NULL,
    expires_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS delivery_attempts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    queue_id TEXT NOT NULL,
    attempted_at INTEGER NOT NULL,
    outcome TEXT NOT NULL,
    detail TEXT
);

CREATE TABLE IF NOT EXISTS telemetry_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_type TEXT NOT NULL,
    details TEXT,
    device_id TEXT,
    timestamp INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS notes (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    tags TEXT,
    created_by TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS media (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    file_path TEXT NOT NULL,
    size INTEGER,
    uploaded_by TEXT,
    uploaded_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS calendar_events (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    start_time INTEGER NOT NULL,
    end_time INTEGER,
    location TEXT,
    attendees TEXT,
    created_by TEXT,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS tasks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    due_date INTEGER,
    priority TEXT NOT NULL CHECK(priority IN ('low','medium','high')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','in_progress','completed')),
    created_by TEXT,
    created_at INTEGER NOT NULL,
    completed_at INTEGER
);

CREATE TABLE IF NOT EXISTS file_conflicts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    file_id TEXT NOT NULL,
    device_id TEXT NOT NULL,
    conflict_type TEXT NOT NULL,
    resolution TEXT,
    detected_at INTEGER NOT NULL,
    resolved_at INTEGER
);

CREATE TABLE IF NOT EXISTS passcodes (
    device_id TEXT PRIMARY KEY,
    passcode TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (device_id) REFERENCES devices(device_id)
);
`
